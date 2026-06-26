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
from app import GroovyBoxApp


def main(page: ft.Page):
    """Initialize and run the GroovyBox application.
    
    Creates the main application instance which sets up the UI,
    audio player, database, and all core functionality.
    
    Args:
        page: The Flet page object provided by the framework.
    """
    GroovyBoxApp(page)


# Launch the application using Flet's built-in runner
ft.run(main)
