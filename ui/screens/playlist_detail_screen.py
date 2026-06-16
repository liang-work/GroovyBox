import flet as ft
from data import playlist_repository as prepo
from logic.localize import tr
from ui.widgets.track_tile import TrackTile


class PlaylistDetailView(ft.Container):
    def __init__(self, page: ft.Page, playlist):
        super().__init__(expand=True)
        self._page = page
        self.playlist = playlist
        self._build()

    def _get_app(self):
        return self._page.session.store.get("app")

    def _build(self):
        tracks = prepo.watch_playlist_tracks(self.playlist.id)

        self.controls = [
            ft.Column(
                expand=True,
                scroll=ft.ScrollMode.AUTO,
                controls=[
                    ft.Container(
                        padding=8,
                        content=ft.IconButton(ft.Icons.ARROW_BACK, on_click=lambda e: self._go_back()),
                    ),
                    ft.Container(
                        padding=ft.Padding(16, 0, 16, 0),
                        content=ft.Row(
                            tight=True,
                            alignment=ft.MainAxisAlignment.CENTER,
                            controls=[
                                ft.FilledButton(tr("playAll"), icon=ft.Icons.PLAY_ARROW, on_click=lambda e: self._play_all()),
                                ft.Container(width=12),
                                ft.OutlinedButton(tr("addToQueue"), icon=ft.Icons.QUEUE_MUSIC, on_click=lambda e: self._add_to_queue(tracks)),
                            ],
                        ),
                    ),
                    ft.Container(
                        expand=True,
                        padding=ft.Padding(16, 0, 16, 0),
                        content=ft.ListView(
                            spacing=4,
                            controls=[
                                TrackTile(
                                    track=t,
                                    leading=ft.Text(str(i + 1).zfill(2), color=ft.Colors.GREY, size=14),
                                    on_tap=lambda e, idx=i: self._play_at(tracks, idx),
                                    padding=4,
                                )
                                for i, t in enumerate(tracks)
                            ] + [ft.Container(height=80)],
                        ),
                    ),
                ],
            ),
        ]

    def _go_back(self):
        self._page.views.pop()
        self._page.run_task(self._page.push_route, self._page.views[-1].route if self._page.views else "/library")

    def _play_all(self, tracks=None, initial_index=0):
        if tracks is None:
            tracks = prepo.watch_playlist_tracks(self.playlist.id)
        if tracks:
            app = self._get_app()
            if app:
                app.audio_player.play_tracks(tracks, initial_index)

    def _play_at(self, tracks, idx):
        self._play_all(tracks, idx)

    def _add_to_queue(self, tracks):
        app = self._get_app()
        if app and tracks:
            for t in tracks:
                app.audio_player.queue.append(t)
            if app.audio_player.on_queue_change:
                app.audio_player.on_queue_change()
