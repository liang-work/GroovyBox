import flet as ft
import threading
from data import db
from data import track_repository as trepo
from logic.localize import tr, load_locale, get_locale
from logic.logger import logger


def SettingsScreen(page: ft.Page) -> ft.Column:
    app = page.session.store.get("app")

    def load_settings():
        return {
            "auto_scan": db.get_setting("auto_scan", "true") == "true",
            "default_player_screen": db.get_setting("default_player_screen", "cover"),
            "lyrics_mode": db.get_setting("lyrics_mode", "auto"),
            "continue_plays": db.get_setting("continue_plays", "false") == "true",
            "theme_mode": db.get_setting("theme_mode", "system"),
        }

    settings = load_settings()

    def save_setting(key, value):
        db.set_setting(key, str(value).lower())
        nonlocal settings
        settings = load_settings()

    def refresh():
        page.update()

    def on_auto_scan_change(e):
        save_setting("auto_scan", e.control.value)
        refresh()

    def on_continue_plays_change(e):
        save_setting("continue_plays", e.control.value)
        refresh()

    def on_language_change(e):
        lang = e.control.value
        load_locale(lang)
        db.set_setting("language", lang)
        page.show_dialog(ft.SnackBar(ft.Text(tr("language") + ": " + lang)))
        if app:
            app._reload_ui()

    def on_default_screen_change(e):
        save_setting("default_player_screen", e.control.value)
        refresh()

    def on_lyrics_mode_change(e):
        save_setting("lyrics_mode", e.control.value)
        refresh()

    def on_theme_mode_change(e):
        val = e.control.value
        save_setting("theme_mode", val)
        mode_map = {"system": ft.ThemeMode.SYSTEM, "light": ft.ThemeMode.LIGHT, "dark": ft.ThemeMode.DARK}
        if app:
            app.theme_mode = mode_map.get(val, ft.ThemeMode.SYSTEM)
            app.page.theme_mode = app.theme_mode
            app.page.update()

    async def add_library(e):
        from logic.file_dialog import pick_directory
        path = await pick_directory(page, title="Select music library folder")
        if path:
            import os
            name = os.path.basename(path)
            conn = db.get_connection()
            try:
                conn.execute(
                    "INSERT OR IGNORE INTO watch_folders (path, name, recursive, is_active) VALUES (?, ?, 1, 1)",
                    (path, name),
                )
                conn.commit()
                trepo.scan_directory(path, recursive=True, callback=lambda: page.update())
            except Exception as ex:
                page.show_dialog(ft.SnackBar(ft.Text(f"Error: {ex}")))
            finally:
                conn.close()
            refresh()

    def scan_libraries(e):
        conn = db.get_connection()
        folders = conn.execute("SELECT * FROM watch_folders WHERE is_active=1").fetchall()
        conn.close()
        if not folders:
            page.show_dialog(ft.SnackBar(ft.Text("No active libraries")))
            page.update()
            return

        def do_scan():
            for f in folders:
                trepo.scan_directory(f["path"], recursive=True, callback=lambda: page.update())

        threading.Thread(target=do_scan, daemon=True).start()
        page.show_dialog(ft.SnackBar(ft.Text(tr("librariesScannedSuccessfully"))))
        page.update()

    def reset_database(e):
        def confirm_yes(e):
            trepo.clear_all_tracks()
            page.pop_dialog()
            page.show_dialog(ft.SnackBar(ft.Text(tr("trackDatabaseReset"))))
            refresh()

        def confirm_no(e):
            page.pop_dialog()
            refresh()

        dlg = ft.AlertDialog(
            title=ft.Text(tr("resetTrackDatabase")),
            content=ft.Text(tr("confirmResetTrackDatabase")),
            actions=[
                ft.TextButton("Cancel", on_click=confirm_no),
                ft.FilledButton("Yes", on_click=confirm_yes, color=ft.Colors.RED),
            ],
        )
        page.show_dialog(dlg)

    # Build libraries list
    conn = db.get_connection()
    folders = conn.execute("SELECT * FROM watch_folders ORDER BY added_at").fetchall()
    conn.close()

    lib_tiles = []
    for f in folders:
        lib_tiles.append(
            ft.ListTile(
                title=ft.Text(f["name"]),
                subtitle=ft.Text(f["path"], size=11),
                trailing=ft.Row(
                    tight=True,
                    controls=[
                        ft.Switch(
                            value=bool(f["is_active"]),
                            on_change=lambda e, fid=f["id"]: _toggle_folder(fid, e.control.value),
                        ),
                        ft.IconButton(
                            ft.Icons.DELETE,
                            on_click=lambda e, fid=f["id"]: _delete_folder(fid),
                        ),
                    ],
                ),
            )
        )

    def _toggle_folder(fid, active):
        conn = db.get_connection()
        conn.execute("UPDATE watch_folders SET is_active=? WHERE id=?", (int(active), fid))
        conn.commit()
        conn.close()
        refresh()

    def _delete_folder(fid):
        conn = db.get_connection()
        conn.execute("DELETE FROM watch_folders WHERE id=?", (fid,))
        conn.commit()
        conn.close()
        refresh()

    def _set_log_level(e):
        lvl = e.control.value
        db.set_setting("log_level", lvl)
        from logic.logger import set_log_level
        set_log_level(lvl)
        refresh()

    async def export_logs(e):
        from logic.file_dialog import save_file
        path = await save_file(page, title="Export logs", default_name="groovybox_logs.txt", extensions=["txt"])
        if path:
            from logic.logger import export_logs as do_export
            try:
                do_export(path)
                page.show_dialog(ft.SnackBar(ft.Text(tr("logsExported", path))))
                logger.info(f"Logs exported to {path}")
            except Exception as ex:
                page.show_dialog(ft.SnackBar(ft.Text(tr("errorExportingLogs", str(ex)))))
                logger.error(f"Failed to export logs: {ex}")

    content = ft.Column(
        scroll=ft.ScrollMode.AUTO,
        spacing=8,
        controls=[
            # Auto Scan Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    controls=[
                        ft.Text(tr("autoScan"), size=18, weight=ft.FontWeight.BOLD),
                        ft.Switch(
                            label=tr("autoScanMusicLibraries"),
                            value=settings["auto_scan"],
                            on_change=on_auto_scan_change,
                        ),
                    ],
                ),
            ),

            # Music Libraries Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    controls=[
                        ft.Row(
                            tight=True,
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                            controls=[
                                ft.Text(tr("musicLibraries"), size=18, weight=ft.FontWeight.BOLD),
                                ft.Row(
                                    tight=True,
                                    controls=[
                                        ft.IconButton(ft.Icons.REFRESH, tooltip=tr("scanLibraries"), on_click=scan_libraries),
                                        ft.IconButton(ft.Icons.ADD, tooltip=tr("addMusicLibrary"), on_click=add_library),
                                    ],
                                ),
                            ],
                        ),
                        ft.Text(tr("addMusicLibraryDescription"), size=12, color=ft.Colors.GREY),
                        *(lib_tiles if lib_tiles else [ft.Text(tr("noMusicLibrariesAdded"), color=ft.Colors.GREY)]),
                    ],
                ),
            ),

            # Player Settings Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    controls=[
                        ft.Text(tr("playerSettings"), size=18, weight=ft.FontWeight.BOLD),
                        ft.Text(tr("playerSettingsDescription"), size=12, color=ft.Colors.GREY),
                        ft.ListTile(
                            title=ft.Text(tr("defaultPlayerScreen")),
                            trailing=ft.Dropdown(
                                value=settings["default_player_screen"],
                                options=[
                                    ft.dropdown.Option("cover", tr("showCover")),
                                    ft.dropdown.Option("lyrics", tr("showLyrics")),
                                    ft.dropdown.Option("queue", tr("showQueue")),
                                ],
                                on_select=on_default_screen_change,
                            ),
                        ),
                        ft.ListTile(
                        title=ft.Text(tr("lyricsMode")),
                        trailing=ft.Dropdown(
                            value=settings["lyrics_mode"],
                            options=[
                                ft.dropdown.Option("auto", "Auto"),
                                ft.dropdown.Option("curved", "Curved"),
                                ft.dropdown.Option("flat", "Flat"),
                            ],
                            on_select=on_lyrics_mode_change,
                            ),
                        ),
                        ft.Switch(
                            label=tr("continuePlaying"),
                            value=settings["continue_plays"],
                            on_change=on_continue_plays_change,
                        ),
                    ],
                ),
            ),

            # App Settings Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    controls=[
                        ft.Text(tr("appSettings"), size=18, weight=ft.FontWeight.BOLD),
                        ft.Text(tr("appSettingsDescription"), size=12, color=ft.Colors.GREY),
                        ft.ListTile(
                            title=ft.Text(tr("language")),
                            trailing=ft.Dropdown(
                                value=get_locale(),
                                options=[
                                    ft.dropdown.Option("en", "English"),
                                    ft.dropdown.Option("zh", tr("chinese")),
                                ],
                                on_select=on_language_change,
                            ),
                        ),
                        ft.ListTile(
                            title=ft.Text(tr("themeMode")),
                            trailing=ft.Dropdown(
                                value=settings["theme_mode"],
                                options=[
                                    ft.dropdown.Option("system", tr("themeSystem")),
                                    ft.dropdown.Option("light", tr("themeLight")),
                                    ft.dropdown.Option("dark", tr("themeDark")),
                                ],
                                on_select=on_theme_mode_change,
                            ),
                        ),
                    ],
                ),
            ),

            # Database Management Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    controls=[
                        ft.Text(tr("databaseManagement"), size=18, weight=ft.FontWeight.BOLD),
                        ft.Text(tr("databaseManagementDescription"), size=12, color=ft.Colors.GREY),
                        ft.ListTile(
                            title=ft.Text(tr("resetTrackDatabase")),
                            trailing=ft.FilledButton(
                                tr("reset"),
                                color=ft.Colors.RED,
                                on_click=reset_database,
                            ),
                        ),
                    ],
                ),
            ),
            # Logs Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    controls=[
                        ft.Text("Logs", size=18, weight=ft.FontWeight.BOLD),
                        ft.Text("View and export application logs.", size=12, color=ft.Colors.GREY),
                        ft.ListTile(
                            title=ft.Text(tr("logLevel")),
                            subtitle=ft.Text(tr("logLevelDescription"), size=11, color=ft.Colors.GREY),
                            trailing=ft.Dropdown(
                                value=db.get_setting("log_level", "normal"),
                                options=[
                                    ft.dropdown.Option("normal", tr("logLevelNormal")),
                                    ft.dropdown.Option("errors_only", tr("logLevelErrorsOnly")),
                                    ft.dropdown.Option("errors_warnings", tr("logLevelErrorsWarnings")),
                                    ft.dropdown.Option("verbose", tr("logLevelVerbose")),
                                ],
                                on_select=lambda e: _set_log_level(e),
                            ),
                        ),
                        ft.ListTile(
                            title=ft.Text(tr("exportLogs")),
                            trailing=ft.FilledButton(
                                tr("exportLogs"),
                                on_click=export_logs,
                            ),
                        ),
                    ],
                ),
            ),
            # About Section
            ft.Container(
                bgcolor=ft.Colors.SURFACE_CONTAINER,
                border_radius=12,
                padding=16,
                content=ft.Column(
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    controls=[
                        ft.Text("GroovyBox", size=20, weight=ft.FontWeight.BOLD),
                        ft.Text("v1.0.0", size=14, color=ft.Colors.with_opacity(0.7, ft.Colors.ON_SURFACE)),
                        ft.Container(height=8),
                        ft.Text("GNU General Public License v3.0", size=12, color=ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
                        ft.Text("Copyright \u00A9 2026 luolingy(liang-work)", size=12, color=ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
                        ft.Container(height=8),
                        ft.Row(
                            tight=True,
                            alignment=ft.MainAxisAlignment.CENTER,
                            controls=[
                                ft.Text("Contributors: ", size=12, color=ft.Colors.with_opacity(0.6, ft.Colors.ON_SURFACE)),
                                ft.TextButton("liang-work", url="https://github.com/liang-work"),
								ft.TextButton("ZhiH", url="https://github.com/ZhiH2333"),
                            ],
                        ),
                    ],
                ),
            ),
            ft.Container(height=80),
        ],
    )

    return ft.Column(
        expand=True,
        scroll=ft.ScrollMode.AUTO,
        controls=[ft.Container(
            expand=True,
            padding=16,
            alignment=ft.Alignment(0, -1),
            content=ft.Container(
                width=min(640, page.width - 32) if page.width else 640,
                content=content,
            ),
        )],
    )
