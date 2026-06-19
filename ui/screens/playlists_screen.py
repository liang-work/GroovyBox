import flet as ft
from data import playlist_repository as prepo
from logic.localize import tr
from data.models import Playlist


def PlaylistsScreen(page: ft.Page) -> ft.Control:
    playlists = prepo.watch_all_playlists()

    def create_new(e):
        name_f = ft.TextField(
            label=tr("playlistName"),
            autofocus=True,
            border_radius=12,
        )

        def do_create(e):
            name = name_f.value
            page.pop_dialog()
            if name and name.strip():
                prepo.create_playlist(name.strip())
                app = page.session.store.get("app")
                if app:
                    app._reload_ui()
                else:
                    page.update()

        bs = ft.BottomSheet(
            content=ft.Container(
                padding=24,
                content=ft.Column(
                    tight=True,
                    controls=[
                        ft.Text(tr("newPlaylist"), size=18, weight=ft.FontWeight.BOLD),
                        name_f,
                        ft.Row(
                            alignment=ft.MainAxisAlignment.END,
                            controls=[
                                ft.TextButton(tr("cancel"), on_click=lambda e: page.pop_dialog()),
                                ft.FilledButton(tr("create"), on_click=do_create),
                            ],
                        ),
                    ],
                ),
            ),
        )
        page.show_dialog(bs)

    def open_playlist(pl):
        page.session.store.set("playlist_data", pl)
        page.run_task(page.push_route, "/playlist")

    tiles = []
    tiles.append(
        ft.ListTile(
            leading=ft.Icon(ft.Icons.ADD),
            title=ft.Text(tr("createOne")),
            subtitle=ft.Text(tr("addNewPlaylist")),
            on_click=create_new,
        ),
    )
    tiles.append(ft.Divider(height=1))

    if not playlists:
        tiles.append(
            ft.Container(
                expand=True,
                alignment=ft.Alignment(0, 0),
                content=ft.Text(tr("noPlaylistsYet"), color=ft.Colors.GREY),
            )
        )
    else:
        for pl in playlists:
            tiles.append(
                ft.ListTile(
                    leading=ft.Icon(ft.Icons.QUEUE_MUSIC),
                    title=ft.Text(pl.name),
                    subtitle=ft.Text(f"{tr('createdAt')} {pl.created_at[:10]}" if pl.created_at else ""),
                    trailing=ft.IconButton(ft.Icons.DELETE, on_click=lambda e, pid=pl.id, pname=pl.name: _delete_pl(pid, pname)),
                    on_click=lambda e, p=pl: open_playlist(p),
                )
            )

    def _delete_pl(pid, pname=""):
        def confirm_yes(e):
            page.pop_dialog()
            prepo.delete_playlist(pid)
            app = page.session.store.get("app")
            if app:
                app._reload_ui()
            else:
                page.update()
        def confirm_no(e):
            page.pop_dialog()
        dlg = ft.AlertDialog(
            title=ft.Text(tr("delete")),
            content=ft.Text(tr("confirmDeletePlaylist").replace("{}", pname)),
            actions=[
                ft.TextButton(tr("cancel"), on_click=confirm_no),
                ft.FilledButton(tr("delete"), color=ft.Colors.RED, on_click=confirm_yes),
            ],
        )
        page.show_dialog(dlg)

    return ft.Column(controls=tiles, scroll=ft.ScrollMode.AUTO)
