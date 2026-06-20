import flet as ft
from logic.logger import logger
from logic.localize import tr, load_locale
from data import db
from logic.metadata_service import get_metadata


class GroovyBoxApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.current_track = None
        self.current_metadata = None
        self.theme_seed_color = "#2EB0C6"
        self.theme_mode = ft.ThemeMode.SYSTEM
        self.shell = None

        db.init_database()
        self._load_locale()
        self._load_theme_mode()
        self._setup_theme()

        from logic.logger import set_log_level
        set_log_level(db.get_setting("log_level", "normal"))

        page.session.store.set("app", self)

        from logic.audio_handler import AudioPlayer
        self.audio_player = AudioPlayer(page)

        self.audio_player.on_track_change = self._on_track_change
        self.audio_player.on_loading_change = self._on_loading_change
        self.audio_player.on_play_state_change = self._on_play_state_change
        self.audio_player.on_position_change = self._on_position_change

        page.on_route_change = self._on_route_change
        page.on_view_pop = self._on_view_pop

        page.title = "GroovyBox"
        try:
            page.window.min_width = 400
            page.window.min_height = 300
        except Exception:
            pass

        page.run_task(page.push_route, "/library")
        self._request_permissions()

    def _request_permissions(self):
        if self.page.platform == ft.PagePlatform.ANDROID:
            try:
                import flet_permission_handler as fph
                self._ph = fph.PermissionHandler()
                self.page.run_task(self._do_request_perms)
            except ImportError:
                pass

    async def _do_request_perms(self):
        try:
            import flet_permission_handler as fph
            await self._ph.request(fph.Permission.READ_EXTERNAL_STORAGE)
            await self._ph.request(fph.Permission.WRITE_EXTERNAL_STORAGE)
        except Exception:
            pass

    def _load_locale(self):
        lang = db.get_setting("language", "en")
        load_locale(lang)

    def _load_theme_mode(self):
        mode = db.get_setting("theme_mode", "system")
        mode_map = {"system": ft.ThemeMode.SYSTEM, "light": ft.ThemeMode.LIGHT, "dark": ft.ThemeMode.DARK}
        self.theme_mode = mode_map.get(mode, ft.ThemeMode.SYSTEM)

    def _setup_theme(self):
        self.page.theme = ft.Theme(
            color_scheme_seed=self.theme_seed_color,
            use_material3=True,
        )
        self.page.dark_theme = ft.Theme(
            color_scheme_seed=self.theme_seed_color,
            use_material3=True,
        )
        self.page.theme_mode = self.theme_mode

    def _on_track_change(self, track_data):
        self.current_track = track_data
        if track_data and track_data.path:
            self._update_metadata(track_data.path)
        self._refresh_ui()

    def _on_loading_change(self, loading):
        self._refresh_ui()

    def _on_play_state_change(self, playing):
        try:
            if self.shell:
                self.shell.mini_player.refresh_play_state(playing)
            self._call_player_method("refresh_play_state", playing)
            self.page.update()
        except Exception as ex:
            logger.warning(f"_on_play_state_change skipped: {ex}")

    def _on_position_change(self, pos_ms):
        try:
            dur_ms = self.audio_player.duration_ms if self.audio_player else 0
            if self.shell:
                self.shell.mini_player.refresh_position(pos_ms, dur_ms)
            self._call_player_method("refresh_position", pos_ms, dur_ms)
        except Exception as ex:
            logger.warning(f"_on_position_change skipped: {ex}")

    def _call_player_method(self, method_name, *args):
        if len(self.page.views) > 0:
            top = self.page.views[-1]
            if getattr(top, 'route', None) == "/player" and top.controls:
                ctrl = top.controls[0]
                method = getattr(ctrl, method_name, None)
                if method:
                    method(*args)

    def _update_metadata(self, path):
        from data import track_repository as trepo
        track = trepo.get_track_by_path(path)
        if track:
            meta = get_metadata(path)
            if track.art_uri and not meta.art_bytes:
                try:
                    with open(track.art_uri, "rb") as f:
                        meta.art_bytes = f.read()
                except Exception:
                    pass
            self.current_metadata = meta
        else:
            self.current_metadata = None

    def _reload_ui(self):
        self._sync_views()

    def _refresh_ui(self):
        try:
            if self.shell:
                self.shell.content_view.update()
                self.shell.mini_player.refresh()
            self._call_player_method("refresh")
            self.page.update()
        except Exception as ex:
            logger.warning(f"_refresh_ui skipped: {ex}")

    def _on_route_change(self, e):
        self._sync_views()

    async def _on_view_pop(self, e):
        if len(self.page.views) > 1:
            self.page.views.pop()
            top = self.page.views[-1]
            await self.page.push_route(top.route)

    def _sync_views(self):
        route = self.page.route
        self.page.on_keyboard_event = None

        if route == "/player":
            self.page.views.clear()
            from ui.screens.player_screen import PlayerScreen
            v = ft.View(
                route="/player",
                padding=0, spacing=0,
                controls=[PlayerScreen(self.page)],
            )
            self.page.views.append(v)
            self.page.update()
            return

        if route == "/live-sync":
            return

        self.page.views.clear()
        from ui.shell import ShellView
        self.shell = ShellView(self.page)

        if route == "/" or route == "/library":
            from ui.screens.library_screen import LibraryScreen
            content = LibraryScreen(self.page)
        elif route == "/artist":
            from ui.screens.artist_detail_screen import ArtistDetailScreen
            artist = self.page.session.store.get("artist_data")
            if artist:
                content = ArtistDetailScreen(self.page, artist)
            else:
                from ui.screens.library_screen import LibraryScreen
                content = LibraryScreen(self.page)
        elif route == "/settings":
            from ui.screens.settings_screen import SettingsScreen
            content = SettingsScreen(self.page)
        elif route == "/album":
            from ui.screens.album_detail_screen import AlbumDetailView
            album = self.page.session.store.get("album_data")
            if album:
                content = AlbumDetailView(self.page, album)
            else:
                from ui.screens.library_screen import LibraryScreen
                content = LibraryScreen(self.page)
        elif route == "/playlist":
            from ui.screens.playlist_detail_screen import PlaylistDetailView
            playlist = self.page.session.store.get("playlist_data")
            if playlist:
                content = PlaylistDetailView(self.page, playlist)
            else:
                from ui.screens.library_screen import LibraryScreen
                content = LibraryScreen(self.page)
        else:
            from ui.screens.library_screen import LibraryScreen
            content = LibraryScreen(self.page)

        self.shell.content_view.controls = [content]
        self.shell.mini_player.bind(self)
        self.page.views.append(self.shell)
        self.shell.mini_player.refresh()
        self.page.update()
