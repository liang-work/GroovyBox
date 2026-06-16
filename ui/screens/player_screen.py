import flet as ft
import json
from data.models import Track, CurrentTrackData
from data import db
from logic.localize import tr
from logic.lyrics_parser import lyrics_from_json, lyrics_to_json, parse as parse_lyrics
from logic.metadata_service import format_duration



def PlayerScreen(page: ft.Page) -> ft.Container:
    app = page.session.store.get("app")
    player = app.audio_player if app else None
    view_mode = page.session.store.get("player_view") or "cover"

    def cycle_view(e):
        nonlocal view_mode
        modes = ["cover", "lyrics", "queue"]
        idx = (modes.index(view_mode) + 1) % 3
        view_mode = modes[idx]
        page.session.store.set("player_view", view_mode)
        refresh()

    def refresh():
        nonlocal app
        app = page.session.store.get("app")
        page.update()

    def build_body():
        if not player or not player.queue:
            return ft.Container(
                expand=True,
                alignment=ft.Alignment(0, 0),
                content=ft.Text(tr("noMediaSelected")),
            )

        track = player.get_current_track()
        meta = app.current_metadata if app else None
        is_mobile = page.width <= 800

        if view_mode == "lyrics":
            content = _build_lyrics_view(page, track, player)
        elif view_mode == "queue":
            content = _build_queue_view(page, player)
        else:
            content = _build_cover_view(page, track, meta, player)

        return ft.Stack(
            expand=True,
            controls=[
                content,
                ft.Container(
                    top=8, right=8,
                    content=ft.IconButton(
                        icon=_get_view_icon(view_mode),
                        icon_size=24,
                        on_click=cycle_view,
                        tooltip=_get_view_tooltip(view_mode),
                    ),
                ),
            ],
        )

    return ft.Container(
        expand=True,
        padding=0,
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            controls=[build_body()],
        ),
    )


def _get_view_icon(mode: str) -> str:
    icons = {"cover": ft.Icons.ALBUM, "lyrics": ft.Icons.LYRICS, "queue": ft.Icons.QUEUE_MUSIC}
    return icons.get(mode, ft.Icons.ALBUM)


def _get_view_tooltip(mode: str) -> str:
    tips = {"cover": tr("showLyrics"), "lyrics": tr("showQueue"), "queue": tr("showCover")}
    return tips.get(mode, "")


def _build_cover_view(page, track, meta, player):
    art_bytes = meta.art_bytes if meta else None
    title = meta.title if meta and meta.title else (track.title if track else "")
    artist = meta.artist if meta and meta.artist else (track.artist or "")

    has_art = track and track.art_uri
    art_content = ft.Image(
        src=track.art_uri,
        fit=ft.BoxFit.COVER,
        error_content=ft.Icon(ft.Icons.MUSIC_NOTE, size=80, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
    ) if has_art else ft.Icon(ft.Icons.MUSIC_NOTE, size=80, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE))

    art = ft.Container(
        width=280, height=280,
        border_radius=24,
        shadow=ft.BoxShadow(blur_radius=20, color=ft.Colors.with_opacity(0.3, ft.Colors.SHADOW)),
        content=art_content,
        bgcolor=ft.Colors.SURFACE_CONTAINER,
        clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
    )

    controls_row = ft.Row(
        tight=True,
        alignment=ft.MainAxisAlignment.CENTER,
        controls=[
            ft.IconButton(
                icon=ft.Icons.SHUFFLE,
                icon_color=ft.Colors.PRIMARY if player.shuffle else ft.Colors.with_opacity(0.4, ft.Colors.ON_SURFACE),
                on_click=lambda e: _toggle_shuffle(page),
            ),
            ft.IconButton(icon=ft.Icons.SKIP_PREVIOUS, icon_size=32, on_click=lambda e: player.previous()),
            ft.Container(
                padding=ft.Padding(12, 0, 12, 0),
                content=ft.IconButton(
                    icon=ft.Icons.PAUSE_ROUNDED if player.is_playing else ft.Icons.PLAY_ARROW_ROUNDED,
                    icon_size=48,
                    on_click=lambda e: player.toggle_play_pause(),
                    bgcolor=ft.Colors.PRIMARY_CONTAINER,
                ),
            ),
            ft.IconButton(icon=ft.Icons.SKIP_NEXT, icon_size=32, on_click=lambda e: player.next()),
            ft.IconButton(
                icon=_repeat_icon(player.repeat_mode),
                icon_color=_repeat_color(player.repeat_mode),
                on_click=lambda e: _toggle_repeat(page),
            ),
        ],
    )

    progress = _build_progress_slider(page, player)

    volume = ft.Row(
        tight=True,
        controls=[
            ft.Icon(ft.Icons.VOLUME_UP, size=16),
            ft.Container(
                width=120,
                content=ft.Slider(
                    value=player.volume * 100,
                    min=0, max=100, divisions=100,
                    on_change=lambda e: player.set_volume(e.control.value / 100),
                ),
            ),
        ],
    )

    return ft.Container(
        expand=True,
        padding=ft.Padding(40, 0, 40, 0),
        content=ft.Column(
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Container(expand=True, alignment=ft.Alignment(0, 0), content=art),
                ft.Text(title, size=22, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                ft.Text(artist, size=16, color=ft.Colors.PRIMARY, text_align=ft.TextAlign.CENTER),
                ft.Container(height=16),
                progress,
                controls_row,
                ft.Container(height=8),
                volume,
                ft.Container(height=32),
            ],
        ),
    )


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


def _build_lyrics_view(page, track, player):
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
        offset = track.lyrics_offset
        pos = player.position_ms + offset
        current_idx = 0
        for i, line in enumerate(data.lines):
            if (line.time_ms or 0) <= pos:
                current_idx = i
            else:
                break

        lines = []
        for i, line in enumerate(data.lines):
            is_active = i == current_idx
            fsize = 18 if is_active else 14
            fw = ft.FontWeight.BOLD if is_active else ft.FontWeight.NORMAL
            color = ft.Colors.PRIMARY if is_active else ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)

            # Simple progress fill effect using Container width
            progress = 0.0
            if is_active:
                start = line.time_ms or 0
                end = (data.lines[i + 1].time_ms or start) if i < len(data.lines) - 1 else player.duration_ms
                if end > start:
                    progress = max(0, min(1, (pos - start) / (end - start)))

            txt = ft.Container(
                padding=ft.Padding(32, 4, 32, 4),
                alignment=ft.Alignment(-1, 0),
                content=ft.Text(line.text, size=fsize, weight=fw, color=color, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                on_click=lambda e, t=line.time_ms: player.seek(t) if t else None,
            )
            lines.append(txt)

        return ft.Column(
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            controls=lines,
        )
    else:
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


def _build_queue_view(page, player):
    if not player.queue:
        return ft.Container(
            expand=True,
            alignment=ft.Alignment(0, 0),
            content=ft.Text(tr("noTracksInQueue")),
        )

    from ui.widgets.track_tile import TrackTile

    tracks = []
    for i, t in enumerate(player.queue):
        is_current = i == player.current_index
        tracks.append(
            TrackTile(
                track=t,
                leading=ft.Text(str(i + 1).zfill(2), size=14),
                is_playing=is_current,
                on_tap=lambda e, idx=i: _jump_to(page, idx),
                padding=4,
            )
        )

    return ft.Column(
        expand=True,
        scroll=ft.ScrollMode.AUTO,
        controls=tracks,
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
