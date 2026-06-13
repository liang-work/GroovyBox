import flet as ft
from logic.localize import tr
from data.track_repository import AUDIO_EXTENSIONS, LYRICS_EXTENSIONS
from ui.widgets.mini_player import MiniPlayerWidget


class ShellView(ft.View):
    def __init__(self, page: ft.Page, services: list = None):
        super().__init__(route="/", padding=0, spacing=0, services=services or [])
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
        fp = None
        for ctrl in self._page.overlay:
            if isinstance(ctrl, ft.FilePicker):
                fp = ctrl
                break
        if fp is None:
            fp = ft.FilePicker()
            self._page.overlay.append(fp)
            self._page.update()
        files = await fp.pick_files(allow_multiple=True, allowed_extensions=all_ext)
        if not files:
            return
        paths = [f.path for f in files]
        from data import track_repository as trepo

        audio_paths = [p for p in paths if p.split(".")[-1].lower() in {"mp3", "m4a", "wav", "flac", "aac", "ogg", "wma", "m4p", "aiff", "au", "dss"}]
        lyrics_paths = [p for p in paths if p.split(".")[-1].lower() in {"lrc", "srt", "txt"}]

        if audio_paths:
            trepo.import_files(audio_paths, callback=lambda: self._page.update())

        if lyrics_paths:
            import os
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
            self._page.show_dialog(ft.SnackBar(ft.Text(f"Batch import: {matched} matched, {not_matched} not matched")))

        self._page.update()
        if self.app:
            self.app._reload_ui()