import flet as ft
from logic.localize import tr
from logic.logger import logger
from data.track_repository import AUDIO_EXTENSIONS, LYRICS_EXTENSIONS
from ui.widgets.mini_player import MiniPlayerWidget


class ShellView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(route="/", padding=0, spacing=0)
        self._page = page
        self.app = page.session.store.get("app")

        self.content_view = ft.Column(expand=True, spacing=0)
        self.mini_player = MiniPlayerWidget(page)

        body = ft.Column(
            expand=True,
            spacing=0,
            controls=[
                self._build_toolbar(),
                self.content_view,
                ft.Container(content=self.mini_player),
            ],
        )

        self.controls = [body]

    @property
    def page(self):
        return self._page

    def refresh_mini_player(self):
        self.mini_player.refresh()

    def _build_toolbar(self):
        return ft.Container(
            height=44,
            bgcolor=ft.Colors.SURFACE_CONTAINER,
            padding=ft.Padding(4, 0, 8, 0),
            content=ft.Row(
                tight=True,
                controls=[
                    ft.Container(expand=True),
                    ft.IconButton(
                        ft.Icons.HOME_OUTLINED,
                        icon_size=20,
                        tooltip=tr("home"),
                        on_click=lambda e: self._page.run_task(self._page.push_route, "/library"),
                    ),
                    ft.IconButton(
                        ft.Icons.SETTINGS_OUTLINED,
                        icon_size=20,
                        tooltip=tr("settings"),
                        on_click=lambda e: self._page.run_task(self._page.push_route, "/settings"),
                    ),
                    ft.IconButton(
                        ft.Icons.ADD_CIRCLE_OUTLINE,
                        icon_size=20,
                        tooltip=tr("importFiles"),
                        on_click=self._import_files,
                    ),
                ],
            ),
        )

    async def _import_files(self, e):
        all_ext = list(AUDIO_EXTENSIONS | LYRICS_EXTENSIONS)
        from logic.file_dialog import pick_files
        paths = await pick_files(title="Select files to import", extensions=all_ext)
        if not paths:
            logger.debug("_import_files: no files selected")
            return
        logger.info(f"_import_files: selected {len(paths)} files: {paths}")
        from data import track_repository as trepo
        import os

        audio_paths = [p for p in paths if p.split(".")[-1].lower() in {"mp3", "m4a", "wav", "flac", "aac", "ogg", "wma", "m4p", "aiff", "au", "dss"}]
        lyrics_paths = [p for p in paths if p.split(".")[-1].lower() in {"lrc", "srt", "txt"}]
        logger.debug(f"_import_files: audio={len(audio_paths)} lyrics={len(lyrics_paths)}")

        reload_needed = False

        if audio_paths:
            trepo.import_files(audio_paths, callback=lambda: self._page.run_task(self._reload_after_import))
            logger.info(f"Import started for {len(audio_paths)} audio files")
            reload_needed = True

        if lyrics_paths:
            all_tracks = trepo.watch_all_tracks()
            matched = 0
            not_matched = 0
            for lp in lyrics_paths:
                base = os.path.splitext(os.path.basename(lp))[0].lower()
                match = None
                for t in all_tracks:
                    if t.title.lower() == base or base in t.title.lower() or t.title.lower() in base:
                        match = t
                        break
                if match:
                    with open(lp, "r", encoding="utf-8", errors="replace") as f:
                        content = f.read()
                    from logic.lyrics_parser import parse, lyrics_to_json
                    ldata = parse(content, os.path.basename(lp))
                    trepo.update_lyrics(match.id, lyrics_to_json(ldata))
                    matched += 1
                else:
                    not_matched += 1
            msg = f"Batch import: {matched} matched, {not_matched} not matched"
            logger.info(msg)
            self._page.show_dialog(ft.SnackBar(ft.Text(msg)))
            reload_needed = True

        if not audio_paths and reload_needed:
            self._page.update()
            if self.app:
                self.app._reload_ui()

    async def _reload_after_import(self):
        self._page.update()
        if self.app:
            self.app._reload_ui()