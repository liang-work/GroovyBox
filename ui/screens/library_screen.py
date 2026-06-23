import flet as ft
import os as _os
from data import track_repository as trepo
from data import playlist_repository as prepo
from data.models import Track
from logic.localize import tr
from logic.metadata_service import format_duration
from ui.widgets.track_tile import TrackTile
from ui.widgets.universal_image import UniversalImage
from logic.logger import logger


class LibraryScreen(ft.Column):
    def __init__(self, page: ft.Page):
        super().__init__(expand=True, spacing=0)
        self._page = page
        self.selected_ids = set()
        self.search_query = ""
        self.selected_tab = 0

        self._build()

    def _get_app(self):
        return self._page.session.store.get("app")

    def _build(self):
        try:
            is_large = self._page.width > 600
            self.controls = [self._build_large_layout() if is_large else self._build_mobile_layout()]
        except Exception as ex:
            logger.exception("LibraryScreen._build failed")

    def _build_large_layout(self):
        nav = ft.NavigationRail(
            selected_index=self.selected_tab,
            on_change=self._on_nav_change,
            extended=self._page.width > 800,
            destinations=[
                ft.NavigationRailDestination(icon=ft.Icons.AUDIOTRACK, label=ft.Text(tr("tracks"))),
                ft.NavigationRailDestination(icon=ft.Icons.ALBUM, label=ft.Text(tr("albums"))),
                ft.NavigationRailDestination(icon=ft.Icons.QUEUE_MUSIC, label=ft.Text(tr("playlists"))),
            ],
        )

        content = self._build_tab_content()

        return ft.Row(
            expand=True,
            spacing=0,
            controls=[
                nav,
                ft.Container(
                    expand=True,
                    bgcolor=ft.Colors.SURFACE,
                    border_radius=ft.border_radius.BorderRadius(16, 0, 0, 0),
                    clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
                    content=content,
                ),
            ],
        )

    def _build_mobile_layout(self):
        def _make_tab(idx, icon, label):
            is_sel = self.selected_tab == idx
            return ft.TextButton(
                content=ft.Row(
                    tight=True,
                    controls=[
                        ft.Icon(icon, size=18, color=ft.Colors.PRIMARY if is_sel else ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
                        ft.Text(label, size=13, weight=ft.FontWeight.BOLD if is_sel else ft.FontWeight.NORMAL,
                                color=ft.Colors.PRIMARY if is_sel else ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
                    ],
                ),
                on_click=lambda e, i=idx: self._on_mobile_tab_change(i),
                style=ft.ButtonStyle(
                    bgcolor=ft.Colors.with_opacity(0.12, ft.Colors.PRIMARY) if is_sel else ft.Colors.TRANSPARENT,
                    shape=ft.RoundedRectangleBorder(radius=8),
                    padding=ft.Padding(12, 8, 12, 8),
                ),
            )

        tab_row = ft.Container(
            padding=ft.Padding(8, 8, 8, 4),
            content=ft.Row(
                tight=True,
                alignment=ft.MainAxisAlignment.SPACE_EVENLY,
                controls=[
                    _make_tab(0, ft.Icons.AUDIOTRACK, tr("tracks")),
                    _make_tab(1, ft.Icons.ALBUM, tr("albums")),
                    _make_tab(2, ft.Icons.QUEUE_MUSIC, tr("playlists")),
                ],
            ),
        )
        content = self._build_tab_content()
        return ft.Column(
            expand=True,
            spacing=0,
            controls=[tab_row, ft.Container(expand=True, content=content)],
        )

    def _on_mobile_tab_change(self, idx):
        self.selected_tab = idx
        self.selected_ids.clear()
        self._build()
        self.update()

    def _on_nav_change(self, e):
        self.selected_tab = int(e.control.selected_index)
        self.selected_ids.clear()
        self._build()
        self.update()

    def _on_tab_change(self, e):
        self.selected_tab = e.control.selected_index
        self.selected_ids.clear()
        self._build()
        self.update()

    def _build_tab_content(self):
        if self.selected_tab == 1:
            from ui.screens.albums_by_artist_screen import AlbumsByArtistScreen
            return AlbumsByArtistScreen(self._page)
        elif self.selected_tab == 2:
            from ui.screens.playlists_screen import PlaylistsScreen
            return PlaylistsScreen(self._page)
        else:
            return self._build_tracks_content()

    def _build_tracks_content(self):
        all_tracks = trepo.watch_all_tracks()
        tracks = self._filter_tracks(all_tracks)

        is_sel_mode = bool(self.selected_ids)

        search_hint = tr("searchTracks")
        if all_tracks:
            if self.search_query:
                q = self.search_query.lower()
                filtered = sum(1 for t in all_tracks if q in t.title.lower() or (t.artist and q in t.artist.lower()) or (t.album and q in t.album.lower()))
                search_hint = tr("searchTracksFiltered").replace("{}", str(filtered)).replace("{}", str(len(all_tracks)))
            else:
                search_hint = tr("searchTracksWithCount").replace("{}", str(len(all_tracks)))

        def on_search(e):
            self.search_query = e.control.value
            self._build()
            self.update()

        if is_sel_mode:
            top_bar = self._build_selection_bar()
        else:
            top_bar = ft.Container(
                padding=ft.Padding(16, 8, 16, 8),
                content=ft.TextField(
                    hint_text=search_hint,
                    prefix_icon=ft.Icons.SEARCH,
                    border=ft.InputBorder.OUTLINE,
                    border_radius=24,
                    dense=True,
                    on_change=on_search,
                    filled=True,
                    fill_color=ft.Colors.with_opacity(0.08, ft.Colors.ON_SURFACE),
                ),
            )

        if not tracks:
            main = ft.Container(
                expand=True,
                alignment=ft.Alignment(0, 0),
                content=ft.Text(tr("noTracksYet"), color=ft.Colors.GREY),
            )
        elif is_sel_mode:
            main = ft.ListView(
                spacing=2,
                padding=ft.Padding(0, 72, 0, 16),
                controls=self._build_selection_tiles(tracks),
            )
        else:
            main = ft.ListView(
                spacing=2,
                padding=ft.Padding(0, 72, 0, 16),
                controls=self._build_track_tiles(tracks),
            )

        return ft.Stack(
            expand=True,
            controls=[main, ft.Container(top=0, left=0, right=0, content=top_bar)],
        )

    def _build_selection_bar(self):
        all_tracks = trepo.watch_all_tracks()
        total = len(all_tracks)
        sel_count = len(self.selected_ids)
        all_selected = sel_count == total

        def do_select_all(e):
            self.selected_ids = {t.id for t in all_tracks}
            self._build()
            self.update()

        def do_deselect_all(e):
            self.selected_ids.clear()
            self._build()
            self.update()

        def do_invert(e):
            current = set(self.selected_ids)
            self.selected_ids = {t.id for t in all_tracks if t.id not in current}
            self._build()
            self.update()

        def do_batch_delete(e):
            self._page.pop_dialog()
            def confirm_yes(e):
                self._page.pop_dialog()
                for tid in list(self.selected_ids):
                    trepo.delete_track(tid)
                self.selected_ids.clear()
                self._build()
                self.update()
            def confirm_no(e):
                self._page.pop_dialog()
            dlg = ft.AlertDialog(
                title=ft.Text(tr("deleteTracks")),
                content=ft.Text(tr("confirmBatchDelete").replace("{}", str(len(self.selected_ids)))),
                actions=[
                    ft.TextButton(tr("cancel"), on_click=confirm_no),
                    ft.FilledButton(tr("delete"), color=ft.Colors.RED, on_click=confirm_yes),
                ],
            )
            self._page.show_dialog(dlg)

        def do_batch_add_playlist(e):
            self._page.pop_dialog()
            self._show_batch_add_to_playlist()

        def do_batch_add_queue(e):
            self._page.pop_dialog()
            app = self._get_app()
            if not app or not app.audio_player:
                return
            all_tracks = trepo.watch_all_tracks()
            selected = [t for t in all_tracks if t.id in self.selected_ids]
            if not selected:
                return
            start_idx = len(app.audio_player.queue)
            app.audio_player.queue.extend(selected)
            if not app.audio_player.is_playing:
                app.audio_player.current_index = start_idx
                app.audio_player._load_current()
            if app.audio_player.on_queue_change:
                app.audio_player.on_queue_change()
            self.selected_ids.clear()
            self._build()
            self.update()

        def do_batch_menu(e):
            bs = ft.BottomSheet(
                content=ft.Column(
                    tight=True,
                    controls=[
                        ft.ListTile(leading=ft.Icon(ft.Icons.QUEUE_MUSIC), title=ft.Text(tr("addToQueue")), on_click=do_batch_add_queue),
                        ft.ListTile(leading=ft.Icon(ft.Icons.PLAYLIST_ADD), title=ft.Text(tr("addToPlaylist")), on_click=do_batch_add_playlist),
                        ft.ListTile(leading=ft.Icon(ft.Icons.DELETE, color=ft.Colors.RED), title=ft.Text(tr("delete"), color=ft.Colors.RED), on_click=do_batch_delete),
                    ],
                ),
            )
            self._page.show_dialog(bs)

        return ft.Container(
            padding=ft.Padding(8, 4, 8, 4),
            bgcolor=ft.Colors.PRIMARY_CONTAINER,
            content=ft.Row(
                tight=True,
                controls=[
                    ft.IconButton(ft.Icons.CLOSE, icon_size=18, on_click=lambda e: self._exit_selection_mode()),
                    ft.Text(f"{sel_count}", size=14, weight=ft.FontWeight.BOLD),
                    ft.Container(expand=True),
                    ft.TextButton(tr("selectAll"), on_click=do_select_all),
                    ft.TextButton(tr("deselectAll"), on_click=do_deselect_all) if all_selected else ft.Container(),
                    ft.TextButton(tr("invertSelection"), on_click=do_invert),
                    ft.IconButton(ft.Icons.MORE_VERT, icon_size=18, on_click=do_batch_menu),
                ],
            ),
        )

    def _exit_selection_mode(self):
        self.selected_ids.clear()
        self._build()
        self.update()

    def _filter_tracks(self, tracks):
        q = self.search_query.lower().strip()
        if not q:
            return tracks
        result = []
        for t in tracks:
            if q in t.title.lower():
                result.append(t)
                continue
            if t.artist and q in t.artist.lower():
                result.append(t)
                continue
            if t.album and q in t.album.lower():
                result.append(t)
                continue
        return result

    def _build_track_tiles(self, tracks):
        tiles = []
        for t in tracks:
            tile = TrackTile(
                track=t,
                show_trailing=True,
                on_tap=lambda e, trk=t: self._play_track(trk),
                on_long_press=lambda e, trk=t: self._toggle_select(trk.id),
                on_trailing_pressed=lambda e, trk=t: self._show_track_options(trk),
                padding=4,
            )
            tiles.append(tile)
        return tiles

    def _build_selection_tiles(self, tracks):
        tiles = []
        for t in tracks:
            is_sel = t.id in self.selected_ids
            tiles.append(
                ft.Container(
                    bgcolor=ft.Colors.with_opacity(0.1, ft.Colors.PRIMARY) if is_sel else ft.Colors.TRANSPARENT,
                    border_radius=8,
                    content=ft.Checkbox(
                        value=is_sel,
                        label=t.title,
                        on_change=lambda e, tid=t.id: self._toggle_select(tid),
                    ),
                    padding=ft.Padding(16, 4, 16, 4),
                )
            )
        return tiles

    def _toggle_select(self, tid):
        if tid in self.selected_ids:
            self.selected_ids.remove(tid)
        else:
            self.selected_ids.add(tid)
        self._build()
        self.update()

    def _play_track(self, track):
        app = self._get_app()
        if app:
            logger.info(f"LibraryScreen._play_track: {track.title}")
            app.audio_player.play_track(track)
        else:
            logger.error("LibraryScreen._play_track: app is None")

    def _show_track_options(self, track):
        def do_add_to_pl(e):
            self._page.pop_dialog()
            self._show_add_to_playlist(track)
        def do_view_details(e):
            self._page.pop_dialog()
            self._show_track_details(track)
        def do_edit(e):
            self._page.pop_dialog()
            self._show_edit_dialog(track)
        def do_delete(e):
            self._page.pop_dialog()
            def confirm_yes(e):
                self._page.pop_dialog()
                trepo.delete_track(track.id)
                self._build()
                self.update()
            def confirm_no(e):
                self._page.pop_dialog()
            dlg = ft.AlertDialog(
                title=ft.Text(tr("deleteTrack")),
                content=ft.Text(tr("confirmDeleteTrack").replace("{}", track.title or "")),
                actions=[
                    ft.TextButton(tr("cancel"), on_click=confirm_no),
                    ft.FilledButton(tr("delete"), color=ft.Colors.RED, on_click=confirm_yes),
                ],
            )
            self._page.show_dialog(dlg)

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
        self._page.show_dialog(bs)

    def _show_batch_add_to_playlist(self):
        playlists = prepo.watch_all_playlists()
        if not playlists:
            self._page.show_dialog(ft.SnackBar(ft.Text(tr("noPlaylistsAvailable"))))
            return

        def pick_pl(e, pl):
            try:
                for tid in self.selected_ids:
                    prepo.add_to_playlist(pl.id, tid)
                self.selected_ids.clear()
                self._page.pop_dialog()
                self._build()
                self.update()
            except Exception as ex:
                logger.exception("_show_batch_add_to_playlist.pick_pl failed")

        dlg = ft.BottomSheet(
            content=ft.Column(
                tight=True,
                controls=[
                    ft.Text(tr("addToPlaylist"), size=18, weight=ft.FontWeight.BOLD),
                    *[ft.ListTile(title=ft.Text(p.name), on_click=lambda e, pl=p: pick_pl(e, pl)) for p in playlists],
                ],
            ),
        )
        self._page.show_dialog(dlg)

    def _show_add_to_playlist(self, track):
        playlists = prepo.watch_all_playlists()
        if not playlists:
            self._page.show_dialog(ft.SnackBar(ft.Text(tr("noPlaylistsAvailable"))))
            return

        def pick_pl(e, pl):
            prepo.add_to_playlist(pl.id, track.id)
            self._page.pop_dialog()

        dlg = ft.BottomSheet(
            content=ft.Column(
                tight=True,
                controls=[
                    ft.Text(tr("addToPlaylist"), size=18, weight=ft.FontWeight.BOLD),
                    *[ft.ListTile(title=ft.Text(p.name), on_click=lambda e, pl=p: pick_pl(e, pl)) for p in playlists],
                ],
            ),
        )
        self._page.show_dialog(dlg)

    def _show_track_details(self, track):
        file_size = tr("unknown")
        try:
            if _os.path.isfile(track.path):
                sz = _os.path.getsize(track.path) / (1024 * 1024)
                file_size = f"{sz:.2f} MB"
        except Exception:
            pass

        rows = [
            self._detail_row(tr("title"), track.title),
            self._detail_row(tr("artist"), track.artist or "Unknown"),
            self._detail_row(tr("album"), track.album or "Unknown"),
            self._detail_row(tr("duration"), format_duration(track.duration)),
            self._detail_row(tr("fileSize"), file_size),
            self._detail_row(tr("filePath"), track.path),
        ]

        dlg = ft.AlertDialog(
            title=ft.Text(tr("trackDetails")),
            content=ft.Column(tight=True, controls=rows),
            actions=[ft.TextButton(tr("close"), on_click=lambda e: self._page.pop_dialog())],
        )
        self._page.show_dialog(dlg)

    def _show_edit_dialog(self, track):
        tf = ft.TextField(label=tr("title"), value=track.title)
        af = ft.TextField(label=tr("artist"), value=track.artist or "")
        alf = ft.TextField(label=tr("album"), value=track.album or "")

        def save(e):
            trepo.update_metadata(track.id, tf.value, af.value or None, alf.value or None)
            self._page.pop_dialog()
            self._build()
            self.update()

        dlg = ft.AlertDialog(
            title=ft.Text(tr("editMetadata")),
            content=ft.Column(tight=True, width=300, controls=[tf, af, alf]),
            actions=[
                ft.TextButton(tr("cancel"), on_click=lambda e: self._page.pop_dialog()),
                ft.FilledButton(tr("save"), on_click=save),
            ],
        )
        self._page.show_dialog(dlg)

    def _detail_row(self, label, value):
        return ft.Row(
            tight=True,
            controls=[
                ft.Container(width=100, content=ft.Text(label + ":", weight=ft.FontWeight.BOLD)),
                ft.Container(expand=True, content=ft.Text(str(value), color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE))),
            ],
        )