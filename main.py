"""GroovyBox Application Entry Point.

This module serves as the main entry point for the GroovyBox music player
application built with the Flet framework. It initializes the Flet page
and launches the main application instance.
"""

import os

# HOME writability test: on iOS, Flet sets HOME to the app container root
# which is read-only. Python stdlib (ssl, pip, history) and Flet itself
# depend on a writable HOME. Redirect to Library/Application Support when
# HOME is not writable (iOS sandbox). No-op on desktop.
_home = os.path.expanduser("~")
if not os.access(_home, os.W_OK):
    os.environ["HOME"] = os.path.join(_home, "Library", "Application Support")

import flet as ft
from flet import FilePicker
from flet_audio import Audio as FletAudio, ReleaseMode
from app import GroovyBoxApp


def main(page: ft.Page):
    """Initialize and run the GroovyBox application.
    
    Pre-creates service instances (FilePicker, Audio) at startup so that:
    1. The Flet build scanner detects the required Flutter plugins
       (file_picker, flet_audio) and includes them in the iOS IPA.
    2. The Flutter client registers the invoke-method handlers,
       preventing TimeoutException on mobile.
    3. All consumers reuse the same instance instead of creating
       new ones on demand.
    
    Args:
        page: The Flet page object provided by the framework.
    """
    page._file_picker = FilePicker()
    page._flet_audio = FletAudio(
        autoplay=False,
        volume=0.8,
        release_mode=ReleaseMode.RELEASE,
    )
    page.update()

    GroovyBoxApp(page)


# Launch the application using Flet's built-in runner
ft.run(main)
