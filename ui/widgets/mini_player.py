import flet as ft
from typing import Optional, Callable
from data.models import CurrentTrackData
from logic.localize import tr


class MiniPlayerWidget(ft.Container):
    def __init__(self, page: ft.Page):
        super().__init__(height=0)
        self._page = page
        self.current_track = None
        self._is_playing = False
        self._is_loading = False
        self._position_ms = 0
        self._duration_ms = 0
        self._volume = 0.8
        self.repeat_mode = "none"
        self.shuffle = False

        self._on_toggle_play = None
        self._on_next = None
        self._on_prev = None
        self._on_seek = None
        self._on_volume_change = None
        self._on_open_player = None
        self._on_toggle_repeat = None
        self._on_toggle_shuffle = None

        self.inner = ft.Column(tight=True, spacing=0)
        self.content = self.inner

    @property
    def page(self):
        return self._page

    def bind(self, app):
        if not app:
            return
        player = app.audio_player
        self._on_toggle_play = player.toggle_play_pause
        self._on_next = player.next
        self._on_prev = player.previous
        self._on_seek = player.seek
        self._on_volume_change = player.set_volume
        self._on_open_player = lambda: self._page.run_task(self._page.push_route, "/player")
        self._on_toggle_repeat = self._toggle_repeat_helper
        self._on_toggle_shuffle = self._toggle_shuffle_helper

    def _toggle_repeat_helper(self):
        app = self._page.session.store.get("app")
        if app and app.audio_player:
            modes = ["none", "one", "all"]
            idx = (modes.index(app.audio_player.repeat_mode) + 1) % 3
            app.audio_player.repeat_mode = modes[idx]
            self.refresh()

    def _repeat_color(self):
        app = self._page.session.store.get("app")
        mode = app.audio_player.repeat_mode if app and app.audio_player else "none"
        if mode in ("one", "all"):
            return ft.Colors.PRIMARY
        return ft.Colors.with_opacity(0.4, ft.Colors.ON_SURFACE)

    def _toggle_shuffle_helper(self):
        app = self._page.session.store.get("app")
        if app and app.audio_player:
            app.audio_player.shuffle = not app.audio_player.shuffle
            self.refresh()

    def refresh(self):
        app = self._page.session.store.get("app")
        if not app or not app.current_track:
            self.height = 0
            self.inner.controls = []
            self.update()
            return

        self.current_track = app.current_track
        player = app.audio_player
        self._is_playing = player.is_playing
        self._is_loading = player.loading
        self._position_ms = player.position_ms
        self._duration_ms = player.duration_ms
        self._volume = player.volume
        self.repeat_mode = player.repeat_mode
        self.shuffle = player.shuffle

        self.height = 72 + (self._page.padding.bottom if self._page.padding else 0)
        is_desktop = self._page.width > 800

        if is_desktop:
            self.inner.controls = [self._build_desktop()]
        else:
            self.inner.controls = [self._build_mobile()]

        self.update()

    def _progress(self) -> ft.Control:
        max_val = max(self._duration_ms, 1)
        pos = max(0, min(self._position_ms, max_val))

        if self._is_loading:
            return ft.Container(
                height=4,
                content=ft.ProgressBar(
                    color=ft.Colors.PRIMARY,
                    bgcolor=ft.Colors.with_opacity(0.1, ft.Colors.ON_SURFACE),
                ),
            )

        return ft.Slider(
            value=float(pos),
            min=0, max=float(max_val),
            divisions=1000,
            height=4,
            thumb_color=ft.Colors.TRANSPARENT,
            active_color=ft.Colors.PRIMARY,
            inactive_color=ft.Colors.with_opacity(0.15, ft.Colors.ON_SURFACE),
            on_change=lambda e: self._on_seek(int(e.control.value)) if self._on_seek else None,
        )

    def _build_mobile(self):
        return ft.Container(
            height=self.height,
            padding=ft.Padding(0, 0, 0, self._page.padding.bottom if self._page.padding else 0),
            on_click=lambda _: self._on_open_player() if self._on_open_player else None,
            bgcolor=ft.Colors.SURFACE_CONTAINER_HIGHEST,
            border=ft.Border(top=ft.BorderSide(color=ft.Colors.OUTLINE_VARIANT, width=1)),
            content=ft.Column(
                tight=True, spacing=0,
                controls=[
                    self._progress(),
                    ft.Container(
                        expand=True,
                        content=ft.Row(
                            tight=True,
                            controls=[
                                ft.Container(
                                    width=56, height=56,
                                    border_radius=8,
                                    clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
                                    content=ft.Image(
                                        src=self.current_track.art_uri,
                                        fit=ft.BoxFit.COVER,
                                        error_content=ft.Icon(ft.Icons.MUSIC_NOTE, color=ft.Colors.WHITE54),
                                    ),
                                    bgcolor=ft.Colors.with_opacity(0.3, ft.Colors.GREY),
                                    margin=ft.Margin(left=8, top=0, right=0, bottom=0),
                                ),
                                ft.Container(
                                    expand=True,
                                    padding=ft.Padding(12, 0, 12, 0),
                                    content=ft.Column(
                                        tight=True, spacing=2,
                                        
                                        controls=[
                                            ft.Text(self.current_track.title or "", weight=ft.FontWeight.BOLD, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS, size=14),
                                            ft.Text(self.current_track.artist or "", max_lines=1, overflow=ft.TextOverflow.ELLIPSIS, size=12, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
                                        ],
                                    ),
                                ),
                                ft.IconButton(ft.Icons.SKIP_PREVIOUS, icon_size=24, on_click=lambda _: self._on_prev() if self._on_prev else None),
                                ft.Container(
                                    padding=ft.Padding(4, 0, 4, 0),
                                    content=ft.IconButton(
                                        icon=ft.Icons.PAUSE_ROUNDED if self._is_playing else ft.Icons.PLAY_ARROW_ROUNDED,
                                        icon_size=28,
                                        on_click=lambda _: self._on_toggle_play() if self._on_toggle_play else None,
                                        bgcolor=ft.Colors.PRIMARY_CONTAINER,
                                    ),
                                ),
                                ft.Container(width=12),
                            ],
                        ),
                    ),
                ],
            ),
        )

    def _build_desktop(self):
        return ft.Container(
            height=self.height,
            padding=ft.Padding(0, 0, 0, self._page.padding.bottom if self._page.padding else 0),
            on_click=lambda _: self._on_open_player() if self._on_open_player else None,
            bgcolor=ft.Colors.SURFACE_CONTAINER_HIGHEST,
            border=ft.Border(top=ft.BorderSide(color=ft.Colors.OUTLINE_VARIANT, width=1)),
            content=ft.Column(
                tight=True, spacing=0,
                controls=[
                    self._progress(),
                    ft.Container(
                        expand=True,
                        content=ft.Row(
                            tight=True,
                            controls=[
                                ft.Container(
                                    expand=3,
                                    content=ft.Row(
                                        tight=True,
                                        controls=[
                                            ft.Container(
                                                width=56, height=56,
                                                border_radius=8,
                                                clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
                                                content=ft.Image(
                                                    src=self.current_track.art_uri,
                                                    fit=ft.BoxFit.COVER,
                                                    error_content=ft.Icon(ft.Icons.MUSIC_NOTE, color=ft.Colors.WHITE54),
                                                ),
                                                bgcolor=ft.Colors.with_opacity(0.3, ft.Colors.GREY),
                                                margin=ft.Margin(left=8, top=0, right=0, bottom=0),
                                            ),
                                            ft.Container(
                                                expand=True,
                                                padding=ft.Padding(12, 0, 12, 0),
                                                content=ft.Column(
                                                    tight=True, spacing=2,
                                                    
                                                    controls=[
                                                        ft.Text(self.current_track.title or "", weight=ft.FontWeight.BOLD, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS, size=14),
                                                        ft.Text(self.current_track.artist or "", max_lines=1, overflow=ft.TextOverflow.ELLIPSIS, size=12, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
                                                    ],
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                                ft.Container(
                                    expand=5,
                                    content=ft.Row(
                                        tight=True,
                                        alignment=ft.MainAxisAlignment.CENTER,
                                        controls=[
                                            ft.IconButton(ft.Icons.REPEAT, icon_size=20, icon_color=self._repeat_color(), on_click=lambda _: self._on_toggle_repeat() if self._on_toggle_repeat else None),
                                            ft.IconButton(ft.Icons.SKIP_PREVIOUS, icon_size=24, on_click=lambda _: self._on_prev() if self._on_prev else None),
                                            ft.Container(
                                                padding=ft.Padding(8, 0, 8, 0),
                                                content=ft.IconButton(
                                                    icon=ft.Icons.PAUSE_ROUNDED if self._is_playing else ft.Icons.PLAY_ARROW_ROUNDED,
                                                    icon_size=32,
                                                    on_click=lambda _: self._on_toggle_play() if self._on_toggle_play else None,
                                                    bgcolor=ft.Colors.PRIMARY_CONTAINER,
                                                ),
                                            ),
                                            ft.IconButton(ft.Icons.SKIP_NEXT, icon_size=24, on_click=lambda _: self._on_next() if self._on_next else None),
                                            ft.IconButton(ft.Icons.QUEUE_MUSIC, icon_size=20, on_click=lambda _: self._on_open_player() if self._on_open_player else None),
                                        ],
                                    ),
                                ),
                                ft.Container(
                                    expand=2,
                                    content=ft.Row(
                                        tight=True,
                                        controls=[
                                            ft.Icon(ft.Icons.VOLUME_UP, size=16, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
                                            ft.Container(
                                                expand=True,
                                                content=ft.Slider(
                                                    value=self._volume * 100,
                                                    min=0, max=100, divisions=100,
                                                    on_change=lambda e: self._on_volume_change(e.control.value / 100) if self._on_volume_change else None,
                                                ),
                                                padding=ft.Padding(0, 0, 24, 0),
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )
