import flet as ft
import os
from data import playlist_repository as prepo
from logic.localize import tr
from logic.logger import logger
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

        self.content = ft.Column(
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
                            ft.Container(width=8),
                            ft.OutlinedButton(tr("addToQueue"), icon=ft.Icons.QUEUE_MUSIC, on_click=lambda e: self._add_to_queue(tracks)),
                            ft.Container(width=8),
                            ft.OutlinedButton(tr("export"), icon=ft.Icons.FILE_DOWNLOAD, on_click=lambda e: self._show_export_dialog()),
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
        )

    def _show_export_dialog(self):
        use_relpath_cb = ft.Checkbox(label=tr("useRelativePaths"), value=False)
        include_lyrics_cb = ft.Checkbox(label=tr("includeLyricsAndCovers"), value=False)
        as_zip_cb = ft.Checkbox(label=tr("packageAsZip"), value=False)
        path_text = ft.Text("", size=12, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE))

        async def pick_path(e):
            from logic.file_dialog import save_file
            ext = ".zip" if as_zip_cb.value else ".m3u"
            p = await save_file(self._page,
                title=tr("export"),
                default_name=f"{self.playlist.name or 'playlist'}{ext}",
                extensions=["zip" if as_zip_cb.value else "m3u"],
            )
            if p:
                path_text.value = p
                path_text.update()

        def do_export(e):
            if not path_text.value:
                return
            try:
                from logic.playlist_exporter import export_playlist
                out = export_playlist(
                    self.playlist.id,
                    path_text.value,
                    use_relpath=use_relpath_cb.value,
                    include_lyrics=include_lyrics_cb.value,
                    include_covers=include_lyrics_cb.value,
                    as_zip=as_zip_cb.value,
                )
                self._page.pop_dialog()
                self._page.show_dialog(ft.SnackBar(ft.Text(tr("exported").replace("{}", os.path.basename(out)))))
            except Exception as ex:
                logger.error(f"Export failed: {ex}")
                self._page.show_dialog(ft.SnackBar(ft.Text(f"{tr('error').replace('{}', str(ex))}")))

        dlg = ft.AlertDialog(
            title=ft.Text(tr("export")),
            content=ft.Column(
                tight=True, width=320,
                controls=[
                    ft.Row(
                        tight=True,
                        controls=[
                            ft.FilledButton(tr("choosePath"), icon=ft.Icons.FOLDER_OPEN, on_click=pick_path),
                            ft.Container(expand=True),
                            path_text,
                        ],
                    ),
                    ft.Container(height=8),
                    use_relpath_cb,
                    include_lyrics_cb,
                    as_zip_cb,
                ],
            ),
            actions=[
                ft.TextButton(tr("cancel"), on_click=lambda e: self._page.pop_dialog()),
                ft.FilledButton(tr("export"), on_click=do_export),
            ],
        )
        self._page.show_dialog(dlg)

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
