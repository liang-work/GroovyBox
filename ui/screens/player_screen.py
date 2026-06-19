import flet as ft
import os
from logic.localize import tr
from logic.lyrics_parser import lyrics_from_json, lyrics_to_json
from logic.metadata_service import format_duration
from data import db
from data import track_repository as trepo
from logic.logger import logger


def _safe_seek(e, player):
    try:
        player.seek(int(e.control.value))
    except RuntimeError:
        pass


def _safe_volume(e, player):
    try:
        player.set_volume(e.control.value / 100)
    except RuntimeError:
        pass


class PlayerScreen(ft.Container):
    def __init__(self, page: ft.Page):
        super().__init__(expand=True, padding=0)
        self._page = page
        self._view_mode = page.session.store.get("player_view") or "cover"

        self._inner = ft.Column(spacing=0)
        self.content = self._inner

        self._pos_slider = None
        self._pos_text = None
        self._dur_text = None
        self._play_btn = None
        self._prev_view_mode = None
        self._last_lyrics_idx = -1
        self._cached_dur = 0
        self._sync_active = False
        self._sync_track = None
        self._sync_temp_offset = 0

        page.on_keyboard_event = self._on_keyboard
        self._initialized = False
        self._rebuild()
        self._initialized = True

    def _get_app(self):
        return self._page.session.store.get("app")

    def _get_player(self):
        app = self._get_app()
        return app.audio_player if app else None

    def _on_keyboard(self, e: ft.KeyboardEvent):
        player = self._get_player()
        if not player:
            return
        if e.key == "Space":
            player.toggle_play_pause()
            self._page.update()
        elif e.key == "Arrow Left":
            player.seek(max(0, player.position_ms - 5000))
            self._page.update()
        elif e.key == "Arrow Right":
            player.seek(min(player.duration_ms, player.position_ms + 5000))
            self._page.update()
        elif e.key == "Arrow Up":
            player.set_volume(min(1.0, player.volume + 0.05))
            self._page.update()
        elif e.key == "Arrow Down":
            player.set_volume(max(0.0, player.volume - 0.05))
            self._page.update()
        elif e.key == "Escape":
                self._page.run_task(self._page.push_route, "/library")

    def cycle_view(self, e=None):
        modes = ["cover", "lyrics"]
        idx = (modes.index(self._view_mode) + 1) % 2 if self._view_mode in modes else 0
        self._view_mode = modes[idx]
        self._page.session.store.set("player_view", self._view_mode)
        self._rebuild()

    def toggle_queue(self, e=None):
        if self._view_mode == "queue":
            self._view_mode = self._prev_view_mode or "cover"
        else:
            self._prev_view_mode = self._view_mode
            self._view_mode = "queue"
        self._page.session.store.set("player_view", self._view_mode)
        self._rebuild()

    def refresh(self):
        self._rebuild()

    def refresh_position(self, pos_ms: int, dur_ms: int):
        if self._pos_slider:
            max_val = max(dur_ms, 1)
            if max_val != getattr(self, '_cached_dur', 0):
                self._pos_slider.min = 0
                self._pos_slider.max = float(max_val)
                self._cached_dur = max_val
            self._pos_slider.value = float(max(0, min(pos_ms, max_val)))
            self._pos_slider.update()
        if self._pos_text:
            self._pos_text.value = format_duration(pos_ms)
            self._pos_text.update()
        if self._dur_text:
            self._dur_text.value = format_duration(dur_ms)
            self._dur_text.update()

        if self._view_mode == "lyrics":
            player = self._get_player()
            if player and player.queue:
                track = player.get_current_track()
                if track and track.lyrics and player.duration_ms > 0:
                    offset = track.lyrics_offset
                    adj_pos = pos_ms + offset
                    new_idx = 0
                    try:
                        data = getattr(self, '_lyrics_data', None)
                        if data and data.type == "timed":
                            for i, ln in enumerate(data.lines):
                                if (ln.time_ms or 0) <= adj_pos:
                                    new_idx = i
                                else:
                                    break
                            if new_idx != self._last_lyrics_idx:
                                self._update_lyrics_styles(new_idx)
                    except Exception:
                        pass

        self._page.update()

    def refresh_play_state(self, is_playing: bool):
        if self._play_btn:
            self._play_btn.icon = ft.Icons.PAUSE_ROUNDED if is_playing else ft.Icons.PLAY_ARROW_ROUNDED
            self._play_btn.update()

    def _rebuild(self):
        if self._sync_active:
            content = self._build_sync_content()
            self._inner.controls = [content]
            if self._initialized:
                self.update()
            return

        app = self._get_app()
        player = self._get_player()

        if not player or not player.queue:
            self._inner.controls = [
                ft.Container(
                    expand=True,
                    alignment=ft.Alignment(0, 0),
                    content=ft.Text(tr("noMediaSelected")),
                )
            ]
            if self._initialized:
                self.update()
            return

        track = player.get_current_track()
        meta = app.current_metadata if app else None
        is_desktop = self._page.width > 800
        ly_mode = db.get_setting("lyrics_mode", "auto")
        use_curved = (ly_mode == "curved") or (ly_mode == "auto" and is_desktop)

        bg = self._build_background(track)
        content = self._build_main_content(track, meta, player, is_desktop, use_curved)

        self._inner.controls = [ft.Stack(expand=True, controls=[bg, content])]
        if self._initialized:
            self.update()

    def _build_background(self, track):
        has_art = track and track.art_uri
        arts = []
        if has_art:
            arts.append(
                ft.Container(
                    expand=True,
                    image=ft.DecorationImage(src=track.art_uri, fit=ft.BoxFit.COVER),
                )
            )
        arts.append(
            ft.Container(
                expand=True,
                bgcolor=ft.Colors.with_opacity(0.65, ft.Colors.SURFACE),
            )
        )
        return ft.Stack(expand=True, controls=arts)

    def _build_main_content(self, track, meta, player, is_desktop, use_curved=False):
        if self._view_mode == "cover":
            inner = self._build_cover_view(track, meta, player, is_desktop)
        elif self._view_mode == "lyrics":
            inner = self._build_split_view(track, meta, player, "lyrics") if is_desktop else self._build_lyrics_view(track, player, use_curved)
        else:
            inner = self._build_split_view(track, meta, player, "queue") if is_desktop else self._build_queue_view(player)

        return ft.Stack(
            expand=True,
            controls=[
                inner,
                ft.Container(
                    left=8, top=8,
                    content=ft.IconButton(
                        icon=ft.Icons.ARROW_BACK,
                        icon_size=24,
                        on_click=lambda _: self._page.run_task(self._page.push_route, "/library"),
                        tooltip=tr("back"),
                    ),
                ),
                ft.Container(
                    right=8, top=8,
                    content=ft.Row(
                        tight=True,
                        controls=[
                            ft.IconButton(
                                icon=_get_view_icon(self._view_mode),
                                icon_size=32,
                                on_click=self.cycle_view,
                                tooltip=_get_view_tooltip(self._view_mode),
                            ),
                            ft.IconButton(
                                icon=ft.Icons.QUEUE_MUSIC,
                                icon_size=32,
                                on_click=self.toggle_queue,
                                tooltip=tr("showCover") if self._view_mode == "queue" else tr("showQueue"),
                                icon_color=ft.Colors.PRIMARY if self._view_mode == "queue" else None,
                            ),
                        ],
                    ),
                ),
            ],
        )

    def _build_split_view(self, track, meta, player, right_mode):
        left = ft.Container(
            content=self._build_cover_view(track, meta, player, is_desktop=True, compact=True),
            expand=3,
        )
        if right_mode == "lyrics":
            right = ft.Container(content=self._build_lyrics_view(track, player, use_curved=True), expand=4)
        else:
            right = ft.Container(content=self._build_queue_view(player), expand=4)
        return ft.Row(expand=True, spacing=0, controls=[left, right])

    def _build_volume_row(self, player):
        pw = self._page.width or 400
        vol_w = max(80, int((min(400, pw - 80)) * 0.85))
        return ft.Row(
            tight=True,
            controls=[
                ft.Icon(ft.Icons.VOLUME_UP, size=20, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
                ft.Container(
                    width=vol_w,
                    content=ft.Slider(
                        value=player.volume * 100, min=0, max=100, divisions=100,
                        on_change=lambda e: _safe_volume(e, player),
                    ),
                ),
            ],
        )

    def _build_cover_view(self, track, meta, player, is_desktop, compact=False):
        has_art = track and track.art_uri
        title = meta.title if meta and meta.title else (track.title if track else "")
        artist = meta.artist if meta and meta.artist else (track.artist or "")

        if compact:
            art_size = 180
        elif is_desktop:
            art_size = min(360, int(self._page.width * 0.28))
        else:
            art_size = min(260, int(self._page.width - 80))

        art_content = ft.Image(
            src=track.art_uri, fit=ft.BoxFit.COVER,
            error_content=ft.Icon(ft.Icons.MUSIC_NOTE, size=art_size // 3, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
        ) if has_art else ft.Icon(ft.Icons.MUSIC_NOTE, size=art_size // 3, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE))

        art = ft.Container(
            width=art_size, height=art_size,
            border_radius=24,
            shadow=ft.BoxShadow(blur_radius=20, color=ft.Colors.with_opacity(0.3, ft.Colors.SHADOW)),
            content=art_content,
            bgcolor=ft.Colors.SURFACE_CONTAINER,
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
        )

        self._play_btn = ft.IconButton(
            icon=ft.Icons.PAUSE_ROUNDED if player.is_playing else ft.Icons.PLAY_ARROW_ROUNDED,
            icon_size=48,
            on_click=lambda e: player.toggle_play_pause(),
            bgcolor=ft.Colors.PRIMARY_CONTAINER,
        )

        ctrl_row = ft.Row(
            tight=True,
            alignment=ft.MainAxisAlignment.CENTER,
            controls=[
                ft.IconButton(ft.Icons.SHUFFLE,
                              icon_color=ft.Colors.PRIMARY if player.shuffle else ft.Colors.with_opacity(0.4, ft.Colors.ON_SURFACE),
                              on_click=lambda e: _toggle_shuffle(self._page)),
                ft.IconButton(ft.Icons.SKIP_PREVIOUS, icon_size=32, on_click=lambda e: player.previous()),
                ft.Container(
                    padding=ft.Padding(12, 0, 12, 0),
                    content=self._play_btn,
                ),
                ft.IconButton(ft.Icons.SKIP_NEXT, icon_size=32, on_click=lambda e: player.next()),
                ft.IconButton(_repeat_icon(player.repeat_mode),
                              icon_color=_repeat_color(player.repeat_mode),
                              on_click=lambda e: _toggle_repeat(self._page)),
            ],
        )

        progress = self._build_progress_slider(player)

        col = ft.Column(
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Container(alignment=ft.Alignment(0, 0), content=art),
                ft.Container(height=12),
                ft.Text(title, size=18 if compact else 22, weight=ft.FontWeight.BOLD,
                        text_align=ft.TextAlign.CENTER, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                ft.Text(artist, size=14 if compact else 16, color=ft.Colors.PRIMARY,
                        text_align=ft.TextAlign.CENTER),
                ft.Container(height=12),
                progress,
                ctrl_row,
                ft.Row(
                    tight=True,
                    controls=[
                        ft.IconButton(
                            icon=ft.Icons.LYRICS,
                            icon_size=20,
                            on_click=lambda e: self._show_lyrics_menu(track, player),
                            tooltip=tr("lyricsOptions"),
                        ),
                        self._build_volume_row(player),
                    ],
                ),
                ft.Container(height=16),
            ],
        )

        return ft.Container(
            expand=True,
            padding=ft.Padding(32, 0, 32, 0) if not compact else ft.Padding(16, 0, 16, 0),
            content=col,
        )

    def _build_progress_slider(self, player):
        max_val = max(player.duration_ms, 1)
        pos_val = max(0, min(player.position_ms, max_val))
        self._pos_slider = ft.Slider(
            value=float(pos_val),
            min=0, max=float(max_val),
            divisions=1000,
            width=min(400, self._page.width - 80) if self._page.width else 400,
            on_change=lambda e: _safe_seek(e, player),
        )
        self._pos_text = ft.Text(format_duration(pos_val), size=12)
        self._dur_text = ft.Text(format_duration(player.duration_ms), size=12)
        return ft.Column(
            tight=True,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                self._pos_slider,
                ft.Row(
                    width=min(400, self._page.width - 80) if self._page.width else 400,
                    tight=True,
                    controls=[
                        self._pos_text,
                        ft.Container(expand=True),
                        self._dur_text,
                    ],
                ),
            ],
        )

    def _build_lyrics_view(self, track, player, use_curved=False):
        if track is None or not track.lyrics:
            return ft.Container(
                expand=True,
                alignment=ft.Alignment(0, 0),
                content=ft.Column(
                    tight=True,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    controls=[
                        ft.Text(tr("noLyricsAvailable")),
                        ft.Container(height=16),
                        ft.TextButton(tr("fetchLyrics"), icon=ft.Icons.DOWNLOAD, on_click=lambda e: self._show_lyrics_options(track, player)),
                    ],
                ),
            )

        try:
            data = lyrics_from_json(track.lyrics)
        except Exception:
            return ft.Container(
                expand=True,
                alignment=ft.Alignment(0, 0),
                content=ft.Text(tr("errorLoadingLyrics").replace("{}", "parse error")),
            )

        if data.type == "timed":
            lyrics_content = self._build_timed_lyrics(data, player, track.lyrics_offset, use_curved)
        else:
            lyrics_content = self._build_plain_lyrics(data)

        return lyrics_content

    def _show_lyrics_menu(self, track, player):
        def do_fetch(e):
            self._page.pop_dialog()
            self._show_fetch_lyrics(track, player)

        def do_manual(e):
            self._page.pop_dialog()
            self._page.run_task(self._import_lyrics_file, track)

        def do_clear(e):
            self._page.pop_dialog()
            self._clear_lyrics(track)

        def do_offset(e):
            self._page.pop_dialog()
            self._sync_active = True
            self._sync_track = track
            self._sync_temp_offset = track.lyrics_offset
            self._rebuild()

        items = [
            ft.ListTile(leading=ft.Icon(ft.Icons.SEARCH), title=ft.Text(tr("fetchLyrics")), on_click=do_fetch),
            ft.ListTile(leading=ft.Icon(ft.Icons.FILE_UPLOAD), title=ft.Text(tr("manualImport")), on_click=do_manual),
        ]
        if track.lyrics:
            items.append(ft.ListTile(leading=ft.Icon(ft.Icons.DELETE, color=ft.Colors.RED), title=ft.Text(tr("clear"), color=ft.Colors.RED), on_click=do_clear))
        items.append(ft.ListTile(leading=ft.Icon(ft.Icons.TUNE), title=ft.Text(tr("offsetMs")), on_click=do_offset))

        bs = ft.BottomSheet(content=ft.Column(tight=True, controls=items))
        self._page.show_dialog(bs)

    def _build_sync_content(self):
        player = self._get_player()
        if not player:
            return ft.Container(expand=True, content=ft.Text(tr("noMediaSelected")))
        track = player.get_current_track()
        max_w = max(480, int((self._page.width or 400) * 0.4))
        offset_text = ft.Text(str(self._sync_temp_offset), size=32,
                              weight=ft.FontWeight.BOLD, color=ft.Colors.PRIMARY)
        fine_slider = ft.Slider(min=-5000, max=5000, divisions=100,
                                value=float(self._sync_temp_offset), on_change=None)
        play_btn = ft.IconButton(
            icon=ft.Icons.PAUSE_ROUNDED if player.is_playing else ft.Icons.PLAY_ARROW_ROUNDED,
            icon_size=36, on_click=lambda e: player.toggle_play_pause())
        self._pos_slider = ft.Slider(
            value=float(player.position_ms), min=0,
            max=max(float(player.duration_ms), 1),
            on_change=lambda e: player.seek(int(e.control.value)))
        self._pos_text = ft.Text(format_duration(player.position_ms), size=12)
        self._dur_text = ft.Text(format_duration(player.duration_ms), size=12)
        self._play_btn = play_btn

        def update_offset(v):
            self._sync_temp_offset = v
            offset_text.value = str(v)
            offset_text.update()
            fine_slider.value = float(v)
            fine_slider.update()

        def on_slider(e):
            update_offset(int(e.control.value))
        fine_slider.on_change = on_slider

        def adjust(delta):
            update_offset(self._sync_temp_offset + delta)

        try:
            preview = self._build_sync_lyrics_preview(track, player, self._sync_temp_offset)
        except Exception:
            preview = None

        inner = [
            ft.Text(tr("offsetMs"), size=14, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
            offset_text,
            ft.Row(tight=True, alignment=ft.MainAxisAlignment.CENTER, controls=[
                ft.IconButton(ft.Icons.FAST_REWIND, icon_size=20, tooltip="-100ms", on_click=lambda e: adjust(-100)),
                ft.IconButton(ft.Icons.KEYBOARD_ARROW_LEFT, icon_size=20, tooltip="-10ms", on_click=lambda e: adjust(-10)),
                ft.TextButton(tr("reset"), on_click=lambda e: adjust(-self._sync_temp_offset)),
                ft.IconButton(ft.Icons.KEYBOARD_ARROW_RIGHT, icon_size=20, tooltip="+10ms", on_click=lambda e: adjust(10)),
                ft.IconButton(ft.Icons.FAST_FORWARD, icon_size=20, tooltip="+100ms", on_click=lambda e: adjust(100)),
            ]),
            ft.Text(tr("fineAdjustment"), size=12, color=ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
            fine_slider,
            ft.Divider(height=1),
            ft.Row(tight=True, alignment=ft.MainAxisAlignment.CENTER, controls=[
                ft.IconButton(ft.Icons.SKIP_PREVIOUS, icon_size=28, on_click=lambda e: player.previous()),
                play_btn,
                ft.IconButton(ft.Icons.SKIP_NEXT, icon_size=28, on_click=lambda e: player.next()),
            ]),
            self._pos_slider,
            ft.Row(tight=True, controls=[self._pos_text, ft.Container(expand=True), self._dur_text]),
            ft.Divider(height=1),
            ft.Text(tr("liveLyricsSync"), size=12, color=ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
            preview if preview else ft.Text(tr("noLyricsAvailable")),
        ]

        return ft.Container(
            expand=True, bgcolor=ft.Colors.SURFACE,
            content=ft.Column(expand=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER, controls=[
                ft.Row(tight=True, controls=[
                    ft.IconButton(ft.Icons.ARROW_BACK, icon_size=24, on_click=lambda e: self._on_sync_back()),
                    ft.Container(expand=True),
                    ft.Text(tr("liveLyricsSync"), size=16, weight=ft.FontWeight.BOLD),
                    ft.Container(expand=True),
                    ft.IconButton(ft.Icons.CHECK, icon_size=24, on_click=lambda e: self._on_sync_save()),
                ]),
                ft.Divider(height=1),
                ft.Container(expand=True, content=ft.Column(expand=True, scroll=ft.ScrollMode.AUTO, controls=[
                    ft.Container(width=max_w, content=ft.Column(tight=True,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=12, controls=inner)),
                ])),
            ]),
        )

    def _on_sync_back(self):
        self._sync_active = False
        self._rebuild()

    def _on_sync_save(self):
        track = self._sync_track
        if track:
            adj = self._sync_temp_offset - track.lyrics_offset
            if adj != 0:
                from data import track_repository as trepo
                trepo.update_lyrics_offset(track.id, self._sync_temp_offset)
                track.lyrics_offset = self._sync_temp_offset
                try:
                    player = self._get_player()
                    if player and hasattr(player, 'current_track') and player.current_track:
                        player.current_track.lyrics_offset = self._sync_temp_offset
                except AttributeError:
                    pass
        self._sync_active = False
        self._rebuild()

    def _build_sync_lyrics_preview(self, track, player, temp_offset):
        if not track or not track.lyrics:
            return None
        try:
            data = lyrics_from_json(track.lyrics)
        except Exception:
            return None
        if data.type != "timed":
            return None
        pos = player.position_ms + temp_offset
        current_idx = 0
        for i, ln in enumerate(data.lines):
            if (ln.time_ms or 0) <= pos:
                current_idx = i
            else:
                break
        items = []
        start = max(0, current_idx - 3)
        end = min(len(data.lines), current_idx + 4)
        for i in range(start, end):
            ln = data.lines[i]
            is_active = i == current_idx
            progress = 0.0
            if is_active:
                s = ln.time_ms or 0
                e = (data.lines[i + 1].time_ms or s) if i < len(data.lines) - 1 else player.duration_ms
                if e > s:
                    progress = max(0.0, min(1.0, (pos - s) / (e - s)))
            if is_active and progress > 0 and progress < 1:
                txt = ft.ShaderMask(
                    shader=ft.LinearGradient(
                        begin=ft.Alignment(-1, 0), end=ft.Alignment(1, 0),
                        colors=[ft.Colors.PRIMARY, ft.Colors.with_opacity(0.5, ft.Colors.ON_SURFACE)],
                        stops=[progress, progress],
                    ),
                    content=ft.Text(ln.text, size=18, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER),
                    blend_mode=ft.BlendMode.SRC_IN,
                )
            else:
                txt = ft.Text(
                    ln.text, size=16 if is_active else 14,
                    weight=ft.FontWeight.BOLD if is_active else ft.FontWeight.NORMAL,
                    color=ft.Colors.PRIMARY if is_active else ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE),
                    text_align=ft.TextAlign.CENTER,
                )
            items.append(ft.Container(padding=ft.Padding(16, 4, 16, 4), content=txt))
        return ft.Column(tight=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER, controls=items)

    def _show_lyrics_options(self, track, player):
        def do_refetch(e):
            self._page.pop_dialog()
            self._show_fetch_lyrics(track, player)

        def do_clear(e):
            self._page.pop_dialog()
            self._clear_lyrics(track)

        def do_manual_import(e):
            self._page.pop_dialog()
            self._page.run_task(self._import_lyrics_file, track)

        def do_adjust_offset(e):
            self._page.pop_dialog()

        items = []
        if track.lyrics:
            items.append(ft.ListTile(leading=ft.Icon(ft.Icons.REFRESH), title=ft.Text(tr("refetch")), on_click=do_refetch))
            items.append(ft.ListTile(leading=ft.Icon(ft.Icons.DELETE, color=ft.Colors.RED), title=ft.Text(tr("clear"), color=ft.Colors.RED), on_click=do_clear))
        else:
            items.append(ft.ListTile(leading=ft.Icon(ft.Icons.SEARCH), title=ft.Text(tr("fetchLyrics")), on_click=do_refetch))
        items.append(ft.ListTile(leading=ft.Icon(ft.Icons.FILE_UPLOAD), title=ft.Text(tr("manualImport")), on_click=do_manual_import))

        bs = ft.BottomSheet(content=ft.Column(tight=True, controls=items))
        self._page.show_dialog(bs)

    def _show_fetch_lyrics(self, track, player):
        def search_musixmatch(e):
            self._page.pop_dialog()
            self._search_lyrics_online(track, "musixmatch")

        def search_netease(e):
            self._page.pop_dialog()
            self._search_lyrics_online(track, "netease")

        def search_lrclib(e):
            self._page.pop_dialog()
            self._search_lyrics_online(track, "lrclib")

        bs = ft.BottomSheet(
            content=ft.Column(
                tight=True,
                controls=[
                    ft.ListTile(leading=ft.Icon(ft.Icons.SEARCH), title=ft.Text(tr("musixmatch")), on_click=search_musixmatch),
                    ft.ListTile(leading=ft.Icon(ft.Icons.SEARCH), title=ft.Text(tr("netease")), on_click=search_netease),
                    ft.ListTile(leading=ft.Icon(ft.Icons.SEARCH), title=ft.Text(tr("lrclib")), on_click=search_lrclib),
                ],
            ),
        )
        self._page.show_dialog(bs)

    def _search_lyrics_online(self, track, source):
        query = f"{track.artist or ''} {track.title or ''}".strip()
        if not query:
            self._page.show_dialog(ft.SnackBar(ft.Text(tr("error").replace("{}", "No track info"))))
            return
        try:
            import urllib.request
            import urllib.parse
            import json as _json
            url = ""
            if source == "lrclib":
                safe = urllib.parse.quote(query)
                url = f"https://lrclib.net/api/search?q={safe}"
            elif source == "netease":
                safe = urllib.parse.quote(query)
                url = f"https://music.163.com/api/search/get?type=1&s={safe}"
            if not url:
                self._page.show_dialog(ft.SnackBar(ft.Text(tr("noLyricsAvailable"))))
                return
            req = urllib.request.Request(url, headers={"User-Agent": "GroovyBox/1.0"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = _json.loads(resp.read().decode("utf-8"))
            lyrics_text = None
            if source == "lrclib" and isinstance(data, list) and data:
                lyrics_text = data[0].get("syncedLyrics") or data[0].get("plainLyrics")
            elif source == "netease":
                songs = data.get("result", {}).get("songs", [])
                if songs:
                    sid = songs[0]["id"]
                    lyric_url = f"https://music.163.com/api/song/lyric?os=pc&id={sid}&lv=-1&kv=-1&tv=-1"
                    lreq = urllib.request.Request(lyric_url, headers={"User-Agent": "GroovyBox/1.0"})
                    with urllib.request.urlopen(lreq, timeout=10) as lresp:
                        ldata = _json.loads(lresp.read().decode("utf-8"))
                    lyric_str = ldata.get("lrc", {}).get("lyric", "")
                    if lyric_str.strip():
                        lyrics_text = lyric_str
            if lyrics_text:
                from logic.lyrics_parser import parse, lyrics_to_json
                lyr_data = parse(lyrics_text, f"{track.title}.lrc")
                json_str = lyrics_to_json(lyr_data)
                trepo.update_lyrics(track.id, json_str)
                player = self._get_player()
                if player and 0 <= player.current_index < len(player.queue):
                    queued = player.queue[player.current_index]
                    if queued.id == track.id:
                        queued.lyrics = json_str
                self._rebuild()
                self._page.show_dialog(ft.SnackBar(ft.Text(tr("importedLyricsLines").replace("{}", str(len(lyr_data.lines))).replace("{}", track.title or ""))))
            else:
                self._page.show_dialog(ft.SnackBar(ft.Text(tr("noLyricsAvailable"))))
        except Exception as ex:
            logger.error(f"Lyrics search failed: {ex}")
            self._page.show_dialog(ft.SnackBar(ft.Text(tr("error").replace("{}", str(ex)))))

    def _clear_lyrics(self, track):
        trepo.update_lyrics(track.id, None)
        player = self._get_player()
        if player and hasattr(player, 'current_track') and player.current_track and player.current_track.id == track.id:
            player.current_track.lyrics = None
        self._rebuild()

    async def _import_lyrics_file(self, track):
        from logic.file_dialog import pick_files
        from data.track_repository import LYRICS_EXTENSIONS
        paths = await pick_files(self._page, title=tr("manualImport"), extensions=list(LYRICS_EXTENSIONS))
        if not paths:
            return
        from logic.encoding_helper import read_with_encoding
        from logic.lyrics_parser import parse, lyrics_to_json
        content = read_with_encoding(paths[0])
        ldata = parse(content, os.path.basename(paths[0]))
        json_str = lyrics_to_json(ldata)
        trepo.update_lyrics(track.id, json_str)
        player = self._get_player()
        if player and 0 <= player.current_index < len(player.queue):
            queued = player.queue[player.current_index]
            if queued.id == track.id:
                queued.lyrics = json_str
        self._rebuild()
        self._page.show_dialog(ft.SnackBar(ft.Text(tr("importedLyricsLines").replace("{}", str(len(ldata.lines))).replace("{}", track.title or ""))))

    def _build_timed_lyrics(self, data, player, offset, use_curved=False):
        pos = player.position_ms + offset
        current_idx = 0
        for i, line in enumerate(data.lines):
            if (line.time_ms or 0) <= pos:
                current_idx = i
            else:
                break
        self._last_lyrics_idx = current_idx
        self._lyrics_data = data
        self._lyrics_use_curved = use_curved
        self._lyrics_offset = offset
        self._lyrics_widgets = []

        total = len(data.lines)
        pw = self._page.width or 400
        is_desktop = pw > 800

        if use_curved:
            HALF_VISIBLE = 5
            ARC_ANGLE = 0.55
        max_w = int(pw * (0.4 if is_desktop else 0.8))
        align_x = -1
        text_align = ft.TextAlign.LEFT

        self._lyrics_widgets = []
        total = len(data.lines)
        if use_curved:
            half = HALF_VISIBLE
            start = max(0, current_idx - half)
            end = min(total, current_idx + half + 1)
            self._lyrics_start = start
            above_spacers = half - (current_idx - start)
            below_spacers = half - (end - 1 - current_idx)
            controls = []

            for _ in range(above_spacers):
                controls.append(ft.Container(height=40))

            for i in range(start, end):
                dist = abs(i - current_idx)
                direction = -1 if i < current_idx else 1
                t = dist / half
                rotate_val = direction * t * ARC_ANGLE
                is_active = i == current_idx
                h_off = int(60 * t * t)
                v_pivot = direction * t * 2 if not is_active else 0
                pivot = ft.Alignment(-1.2, v_pivot)

                if is_active:
                    fsize, fw, color = 18, ft.FontWeight.BOLD, ft.Colors.PRIMARY
                else:
                    fsize, fw, color = 16, ft.FontWeight.NORMAL, ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)

                txt_container = ft.Container(
                    height=40,
                    padding=ft.Padding(32 - h_off, 0, 24, 0),
                    alignment=ft.Alignment(-1, 0),
                    rotate=ft.Rotate(rotate_val, pivot) if use_curved else None,
                    width=max_w,
                    on_click=lambda e, t=data.lines[i].time_ms: player.seek(t) if t else None,
                )
                txt_container.content = ft.Text(data.lines[i].text, size=fsize, weight=fw,
                                                color=color, max_lines=1,
                                                overflow=ft.TextOverflow.ELLIPSIS,
                                                text_align=text_align)
                self._lyrics_widgets.append(txt_container)
                controls.append(txt_container)

            for _ in range(below_spacers):
                controls.append(ft.Container(height=40))

            return ft.Container(
                expand=True,
                padding=ft.Padding(48, 10, 16, 10),
                content=ft.Column(
                    expand=True,
                    alignment=ft.MainAxisAlignment.CENTER,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=4,
                    controls=controls,
                ),
            )
        else:
            self._lyrics_start = 0
            lines = []
            for i, line in enumerate(data.lines):
                is_active = i == current_idx
                if is_active:
                    fsize, fw, color = 18, ft.FontWeight.BOLD, ft.Colors.PRIMARY
                else:
                    fsize, fw, color = 16, ft.FontWeight.NORMAL, ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)

                txt_container = ft.Container(
                    height=36,
                    padding=ft.Padding(32, 0, 24, 0),
                    alignment=ft.Alignment(-1, 0),
                    width=max_w,
                    on_click=lambda e, t=line.time_ms: player.seek(t) if t else None,
                )
                txt_container.content = ft.Text(line.text, size=fsize, weight=fw,
                                                color=color, max_lines=1,
                                                overflow=ft.TextOverflow.ELLIPSIS,
                                                text_align=text_align)
                self._lyrics_widgets.append(txt_container)
                lines.append(txt_container)

            return ft.Container(
                expand=True,
                padding=ft.Padding(0, 20, 0, 20),
                content=ft.Column(
                    expand=True,
                    alignment=ft.MainAxisAlignment.CENTER,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    controls=lines,
                ),
            )

    def _update_lyrics_styles(self, new_idx):
        data = self._lyrics_data
        use_curved = getattr(self, '_lyrics_use_curved', False)
        total = len(data.lines)

        HALF_VISIBLE = 5
        ARC_ANGLE = 0.55
        half = HALF_VISIBLE
        start = getattr(self, '_lyrics_start', 0)

        if use_curved:
            self._rebuild()
            return

        for i, container in enumerate(self._lyrics_widgets):
            line_idx = start + i
            dist = abs(line_idx - new_idx)

            if use_curved:
                in_range = dist <= half
                container.opacity = 1.0 if in_range else 0.0
                direction = -1 if line_idx < new_idx else 1
                t = min(dist / half, 1.0) if dist > 0 else 0
                v_pivot = direction * t * 2 if line_idx != new_idx else 0
                pivot = ft.Alignment(-1.2, v_pivot)
                container.rotate = ft.Rotate(direction * t * ARC_ANGLE, pivot) if in_range else ft.Rotate(0, ft.Alignment(-1.2, 0))
                h_off = int(60 * t * t) if dist > 0 else 0
                container.padding = ft.Padding(32 - h_off, 0, 24, 0)
                container.alignment = ft.Alignment(-1, 0)

                if line_idx == new_idx:
                    fsize, fw, color = 18, ft.FontWeight.BOLD, ft.Colors.PRIMARY
                else:
                    fsize, fw, color = 16, ft.FontWeight.NORMAL, ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)
            else:
                container.rotate = None
                container.padding = ft.Padding(32, 0, 32, 0)
                container.alignment = ft.Alignment(0, 0)
                if line_idx == new_idx:
                    fsize, fw, color = 18, ft.FontWeight.BOLD, ft.Colors.PRIMARY
                else:
                    fsize, fw, color = 16, ft.FontWeight.NORMAL, ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)

            txt = container.content
            txt.size = fsize
            txt.weight = fw
            txt.color = color
            container.update()

        self._last_lyrics_idx = new_idx

    def _build_plain_lyrics(self, data):
        return ft.Column(
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            controls=[
                ft.Container(
                    padding=ft.Padding(32, 4, 32, 4),
                    content=ft.Text(line.text, size=16, text_align=ft.TextAlign.CENTER),
                )
                for line in data.lines
            ],
        )

    def _build_queue_view(self, player):
        if not player.queue:
            return ft.Container(
                expand=True,
                alignment=ft.Alignment(0, 0),
                content=ft.Text(tr("noTracksInQueue")),
            )

        from ui.widgets.track_tile import TrackTile

        def on_reorder(e):
            old_idx = e.old_index if hasattr(e, 'old_index') else e.oldIndex
            new_idx = e.new_index if hasattr(e, 'new_index') else e.newIndex
            if old_idx < new_idx:
                for i in range(old_idx, new_idx):
                    player.queue[i], player.queue[i + 1] = player.queue[i + 1], player.queue[i]
            elif old_idx > new_idx:
                for i in range(old_idx, new_idx, -1):
                    player.queue[i], player.queue[i - 1] = player.queue[i - 1], player.queue[i]
            if player.current_index == old_idx:
                player.current_index = new_idx
            elif old_idx < player.current_index <= new_idx:
                player.current_index -= 1
            elif new_idx <= player.current_index < old_idx:
                player.current_index += 1
            self._rebuild()

        tracks = []
        for i, t in enumerate(player.queue):
            is_current = i == player.current_index
            tile = TrackTile(
                track=t,
                leading=ft.Text(str(i + 1).zfill(2), size=14),
                is_playing=is_current,
                on_tap=lambda e, idx=i: _jump_to(self._page, idx),
                padding=4,
                show_trailing=True,
                trailing_icon=ft.Icons.DELETE,
                on_trailing_pressed=lambda e, idx=i: self._remove_from_queue(idx),
            )
            tracks.append(tile)

        return ft.Container(
            expand=True,
            padding=ft.Padding(16, 80, 16, 80),
            content=ft.ReorderableListView(
                expand=True,
                controls=tracks,
                on_reorder=on_reorder,
                show_default_drag_handles=True,
            ),
        )

    def _remove_from_queue(self, idx):
        player = self._get_player()
        if not player or idx < 0 or idx >= len(player.queue):
            return
        player.queue.pop(idx)
        if idx < player.current_index:
            player.current_index -= 1
        elif idx == player.current_index:
            if player.queue:
                player.current_index = min(player.current_index, len(player.queue) - 1)
                player._load_current()
            else:
                player.current_index = -1
                player._is_playing = False
            self._page.run_task(self._page.push_route, "/library")
                return
        self._rebuild()


def _get_view_icon(mode: str) -> str:
    return ft.Icons.LYRICS if mode == "cover" else ft.Icons.ALBUM


def _get_view_tooltip(mode: str) -> str:
    return tr("showLyrics") if mode == "cover" else tr("showCover")


def _build_progress_slider(page, player):
    max_val = max(player.duration_ms, 1)
    pos_val = max(0, min(player.position_ms, max_val))
    return ft.Column(
        tight=True,
        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        controls=[
            ft.Slider(
                value=float(pos_val),
                min=0, max=float(max_val),
                divisions=1000,
                width=min(400, page.width - 80) if page.width else 400,
                on_change=lambda e: player.seek(int(e.control.value)),
            ),
            ft.Row(
                width=min(400, page.width - 80) if page.width else 400,
                tight=True,
                controls=[
                    ft.Text(format_duration(pos_val), size=12),
                    ft.Container(expand=True),
                    ft.Text(format_duration(player.duration_ms), size=12),
                ],
            ),
        ],
    )





def _jump_to(page, index):
    app = page.session.store.get("app")
    if app and app.audio_player:
        app.audio_player.current_index = index
        app.audio_player._load_current()


def _toggle_shuffle(page):
    app = page.session.store.get("app")
    if app and app.audio_player:
        app.audio_player.shuffle = not app.audio_player.shuffle
        page.update()


def _toggle_repeat(page):
    app = page.session.store.get("app")
    if app and app.audio_player:
        modes = ["none", "one", "all"]
        idx = (modes.index(app.audio_player.repeat_mode) + 1) % 3
        app.audio_player.repeat_mode = modes[idx]
        page.update()


def _repeat_icon(mode: str) -> str:
    return {None: ft.Icons.REPEAT, "none": ft.Icons.REPEAT, "one": ft.Icons.REPEAT_ONE, "all": ft.Icons.REPEAT}.get(mode, ft.Icons.REPEAT)


def _repeat_color(mode: str):
    if mode in ("one", "all"):
        return ft.Colors.PRIMARY
    return ft.Colors.with_opacity(0.4, ft.Colors.ON_SURFACE)
