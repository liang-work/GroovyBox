import flet as ft
from logic.localize import tr
from logic.lyrics_parser import lyrics_from_json
from logic.metadata_service import format_duration


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
            self._page.go("/library")

    def cycle_view(self, e=None):
        modes = ["cover", "lyrics", "queue"]
        idx = (modes.index(self._view_mode) + 1) % 3
        self._view_mode = modes[idx]
        self._page.session.store.set("player_view", self._view_mode)
        self._rebuild()

    def refresh(self):
        self._rebuild()

    def refresh_position(self, pos_ms: int, dur_ms: int):
        if self._pos_slider:
            max_val = max(dur_ms, 1)
            self._pos_slider.min = 0
            self._pos_slider.max = float(max_val)
            self._pos_slider.value = float(max(0, min(pos_ms, max_val)))
            self._pos_slider.update()
        if self._pos_text:
            self._pos_text.value = format_duration(pos_ms)
            self._pos_text.update()
        if self._dur_text:
            self._dur_text.value = format_duration(dur_ms)
            self._dur_text.update()

    def refresh_play_state(self, is_playing: bool):
        if self._play_btn:
            self._play_btn.icon = ft.Icons.PAUSE_ROUNDED if is_playing else ft.Icons.PLAY_ARROW_ROUNDED
            self._play_btn.update()

    def _rebuild(self):
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

        bg = self._build_background(track)
        content = self._build_main_content(track, meta, player, is_desktop)

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

    def _build_main_content(self, track, meta, player, is_desktop):
        if self._view_mode == "cover":
            inner = self._build_cover_view(track, meta, player, is_desktop)
        elif self._view_mode == "lyrics":
            inner = self._build_split_view(track, meta, player, "lyrics") if is_desktop else self._build_lyrics_view(track, player)
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
                        on_click=lambda _: self._page.go("/library"),
                        tooltip=tr("back"),
                    ),
                ),
                ft.Container(
                    right=8, top=8,
                    content=ft.IconButton(
                        icon=_get_view_icon(self._view_mode),
                        icon_size=24,
                        on_click=self.cycle_view,
                        tooltip=_get_view_tooltip(self._view_mode),
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
            right = ft.Container(content=self._build_lyrics_view(track, player), expand=4)
        else:
            right = ft.Container(content=self._build_queue_view(player), expand=4)
        return ft.Row(expand=True, spacing=0, controls=[left, right])

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
        volume = ft.Row(
            tight=True,
            controls=[
                ft.Icon(ft.Icons.VOLUME_UP, size=16),
                ft.Container(
                    width=120,
                    content=ft.Slider(
                        value=player.volume * 100, min=0, max=100, divisions=100,
                        on_change=lambda e: player.set_volume(e.control.value / 100),
                    ),
                ),
            ],
        )

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
                volume if not compact else ft.Container(),
                ft.Container(height=24 if not compact else 8),
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
            on_change=lambda e: player.seek(int(e.control.value)),
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

    def _build_lyrics_view(self, track, player):
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
                        ft.TextButton(tr("fetchLyrics"), icon=ft.Icons.DOWNLOAD),
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
            return self._build_timed_lyrics(data, player, track.lyrics_offset)
        else:
            return self._build_plain_lyrics(data)

    def _build_timed_lyrics(self, data, player, offset):
        pos = player.position_ms + offset
        current_idx = 0
        for i, line in enumerate(data.lines):
            if (line.time_ms or 0) <= pos:
                current_idx = i
            else:
                break

        ITEM_HEIGHT = 40

        lines = []
        for i, line in enumerate(data.lines):
            is_active = i == current_idx
            fsize = 20 if is_active else 16
            fw = ft.FontWeight.BOLD if is_active else ft.FontWeight.NORMAL

            if is_active:
                start = line.time_ms or 0
                end = (data.lines[i + 1].time_ms or start) if i < len(data.lines) - 1 else player.duration_ms
                progress = max(0.0, min(1.0, (pos - start) / (end - start))) if end > start else 0.0
                active_color = ft.Colors.PRIMARY
                inactive_color = ft.Colors.with_opacity(0.5, ft.Colors.ON_SURFACE)

                txt = ft.Container(
                    height=ITEM_HEIGHT,
                    padding=ft.Padding(32, 6, 32, 6),
                    alignment=ft.Alignment(-1, 0),
                    content=ft.ShaderMask(
                        shader=ft.LinearGradient(
                            begin=ft.Alignment(-1, 0),
                            end=ft.Alignment(1, 0),
                            colors=[active_color, inactive_color],
                            stops=[progress, progress],
                        ),
                        content=ft.Text(line.text, size=fsize, weight=fw, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                        blend_mode=ft.BlendMode.SRC_IN,
                    ),
                    on_click=lambda e, t=line.time_ms: player.seek(t) if t else None,
                )
            else:
                txt = ft.Container(
                    height=ITEM_HEIGHT,
                    padding=ft.Padding(32, 6, 32, 6),
                    alignment=ft.Alignment(-1, 0),
                    content=ft.Text(line.text, size=fsize, weight=fw,
                                    color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE),
                                    max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                    on_click=lambda e, t=line.time_ms: player.seek(t) if t else None,
                )

            lines.append(txt)

        return ft.Container(
            expand=True,
            padding=ft.Padding(0, 80, 0, 80),
            content=ft.ListView(
                expand=True,
                spacing=2,
                controls=lines,
            ),
        )

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
        self._rebuild()


def _get_view_icon(mode: str) -> str:
    icons = {"cover": ft.Icons.ALBUM, "lyrics": ft.Icons.LYRICS, "queue": ft.Icons.QUEUE_MUSIC}
    return icons.get(mode, ft.Icons.ALBUM)


def _get_view_tooltip(mode: str) -> str:
    tips = {"cover": tr("showLyrics"), "lyrics": tr("showQueue"), "queue": tr("showCover")}
    return tips.get(mode, "")


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
