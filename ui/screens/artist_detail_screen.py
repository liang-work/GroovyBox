import flet as ft
from data import playlist_repository as prepo
from logic.localize import tr
from ui.widgets.track_tile import TrackTile
from logic.metadata_service import format_duration


def ArtistDetailScreen(page: ft.Page, artist_name: str) -> ft.Control:
    tracks = prepo.watch_artist_tracks(artist_name)

    def play_all(e):
        app = page.session.store.get("app")
        if app and tracks:
            app.audio_player.play_tracks(tracks)

    header = ft.Container(
        padding=16,
        content=ft.Row([
            ft.Container(
                width=80, height=80, border_radius=40,
                bgcolor=ft.Colors.with_opacity(0.2, ft.Colors.PRIMARY),
                alignment=ft.Alignment(0, 0),
                content=ft.Icon(ft.Icons.PERSON, size=40, color=ft.Colors.PRIMARY),
            ),
            ft.Container(width=16),
            ft.Column([
                ft.Text(artist_name, size=22, weight=ft.FontWeight.BOLD),
                ft.Text(f"{len(tracks)} {tr('tracks')}", size=13, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
            ]),
            ft.Container(expand=True),
            ft.FilledButton(tr("playAll"), on_click=play_all),
        ]),
    )

    track_tiles = []
    for t in tracks:
        tile = TrackTile(
            track=t,
            show_trailing=True,
            on_tap=lambda e, trk=t: _play_track(trk),
            on_long_press=lambda e, trk=t: _show_options(trk),
            on_trailing_pressed=lambda e, trk=t: _show_options(trk),
            padding=4,
        )
        track_tiles.append(tile)

    def _play_track(track):
        app = page.session.store.get("app")
        if app:
            app.audio_player.play_track(track)

    def _show_options(track):
        def do_add_to_pl(e):
            page.pop_dialog()
            _show_add_to_playlist(track)
        def do_view_details(e):
            page.pop_dialog()
            _show_track_details(track)
        def do_edit(e):
            page.pop_dialog()
            _show_edit_dialog(track)
        def do_delete(e):
            page.pop_dialog()
            from data import track_repository as trepo
            trepo.delete_track(track.id)
            page.run_task(page.push_route, "/library")

        bs = ft.BottomSheet(
            content=ft.Column(
                tight=True,
                controls=[
                    ft.ListTile(leading=ft.Icon(ft.Icons.PLAYLIST_ADD), title=ft.Text(tr("addToPlaylist")), on_click=do_add_to_pl),
                    ft.ListTile(leading=ft.Icon(ft.Icons.INFO), title=ft.Text(tr("viewDetails")), on_click=do_view_details),
                    ft.ListTile(leading=ft.Icon(ft.Icons.EDIT), title=ft.Text(tr("editMetadata")), on_click=do_edit),
                    ft.ListTile(leading=ft.Icon(ft.Icons.DELETE, color=ft.Colors.RED), title=ft.Text(tr("delete"), color=ft.Colors.RED), on_click=do_delete),
                ],
            ),
        )
        page.show_dialog(bs)

    def _show_add_to_playlist(track):
        playlists = prepo.watch_all_playlists()
        if not playlists:
            page.show_dialog(ft.SnackBar(ft.Text(tr("noPlaylistsAvailable"))))
            return
        def pick_pl(e, pl):
            prepo.add_to_playlist(pl.id, track.id)
            page.pop_dialog()
            page.show_dialog(ft.SnackBar(ft.Text(tr("addedToPlaylist").replace("{}", pl.name))))
        dlg = ft.BottomSheet(
            content=ft.Column(
                tight=True,
                controls=[
                    ft.Text(tr("addToPlaylist"), size=18, weight=ft.FontWeight.BOLD),
                    *[ft.ListTile(title=ft.Text(p.name), on_click=lambda e, pl=p: pick_pl(e, pl)) for p in playlists],
                ],
            ),
        )
        page.show_dialog(dlg)

    def _show_track_details(track):
        import os as _os
        file_size = tr("unknown")
        try:
            if _os.path.isfile(track.path):
                sz = _os.path.getsize(track.path) / (1024 * 1024)
                file_size = f"{sz:.2f} MB"
        except Exception:
            pass
        rows = [
            _detail_row(tr("title"), track.title),
            _detail_row(tr("artist"), track.artist or "Unknown"),
            _detail_row(tr("album"), track.album or "Unknown"),
            _detail_row(tr("duration"), format_duration(track.duration)),
            _detail_row(tr("fileSize"), file_size),
            _detail_row(tr("filePath"), track.path),
        ]
        dlg = ft.AlertDialog(
            title=ft.Text(tr("trackDetails")),
            content=ft.Column(tight=True, controls=rows),
            actions=[ft.TextButton(tr("close"), on_click=lambda e: page.pop_dialog())],
        )
        page.show_dialog(dlg)

    def _show_edit_dialog(track):
        tf = ft.TextField(label=tr("title"), value=track.title)
        af = ft.TextField(label=tr("artist"), value=track.artist or "")
        alf = ft.TextField(label=tr("album"), value=track.album or "")
        def save(e):
            from data import track_repository as trepo
            trepo.update_metadata(track.id, tf.value, af.value or None, alf.value or None)
            page.pop_dialog()
            page.run_task(page.push_route, "/library")
        dlg = ft.AlertDialog(
            title=ft.Text(tr("editMetadata")),
            content=ft.Column(tight=True, width=300, controls=[tf, af, alf]),
            actions=[
                ft.TextButton(tr("cancel"), on_click=lambda e: page.pop_dialog()),
                ft.FilledButton(tr("save"), on_click=save),
            ],
        )
        page.show_dialog(dlg)

    def _detail_row(label, value):
        return ft.Row(
            tight=True,
            controls=[
                ft.Container(width=100, content=ft.Text(label + ":", weight=ft.FontWeight.BOLD)),
                ft.Container(expand=True, content=ft.Text(str(value), color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE))),
            ],
        )

    return ft.Column(
        expand=True,
        spacing=0,
        controls=[
            header,
            ft.Divider(height=1),
            ft.Container(expand=True, content=ft.Column(
                spacing=2,
                scroll=ft.ScrollMode.AUTO,
                controls=track_tiles,
            )),
        ],
    )
