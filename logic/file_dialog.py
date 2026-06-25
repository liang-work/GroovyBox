"""File Dialog Module for GroovyBox.

This module provides wrapper functions for Flet's FilePicker,
offering a simplified API for common file operations: picking files,
selecting directories, and saving files. Handles platform-specific
error cases gracefully.
"""

import logging
from typing import Optional, List

import flet as ft

logger = logging.getLogger("flet")

# Module-level FilePicker instance (reused across calls)
_picker: Optional[ft.FilePicker] = None


def _ensure_picker(page: ft.Page) -> ft.FilePicker:
    """Get or create the shared FilePicker instance.
    
    Args:
        page: The Flet page to attach the picker to.
    
    Returns:
        The shared FilePicker instance.
    """
    global _picker
    if _picker is None:
        _picker = ft.FilePicker()
    return _picker


async def pick_files(
    page: ft.Page,
    title: str = "Select files",
    extensions: Optional[List[str]] = None,
    allow_multiple: bool = True,
) -> Optional[List[str]]:
    """Open a file picker dialog for selecting files.
    
    Args:
        page: The Flet page instance.
        title: Dialog window title.
        extensions: List of allowed file extensions (e.g., ["mp3", "flac"]).
        allow_multiple: Whether multiple files can be selected.
    
    Returns:
        List of selected file paths, or None if cancelled.
    """
    picker = _ensure_picker(page)
    try:
        file_type = ft.FilePickerFileType.CUSTOM if extensions else ft.FilePickerFileType.ANY
        result = await picker.pick_files(
            dialog_title=title,
            allowed_extensions=extensions,
            allow_multiple=allow_multiple,
            file_type=file_type,
        )
        return [f.path for f in result if f.path] if result else None
    except Exception as e:
        logger.error("FilePicker.pick_files failed: %s", e)
        return None


async def pick_directory(
    page: ft.Page,
    title: str = "Select folder",
) -> Optional[str]:
    """Open a directory picker dialog.
    
    Args:
        page: The Flet page instance.
        title: Dialog window title.
    
    Returns:
        Selected directory path, or None if cancelled.
    """
    picker = _ensure_picker(page)
    try:
        path = await picker.get_directory_path(dialog_title=title)
        return path
    except Exception as e:
        logger.warning("FilePicker.get_directory_path failed: %s", e)
        return None


async def save_file(
    page: ft.Page,
    title: str = "Save file",
    default_name: str = "file",
    extensions: Optional[List[str]] = None,
) -> Optional[str]:
    """Open a save file dialog.
    
    Args:
        page: The Flet page instance.
        title: Dialog window title.
        default_name: Default filename suggestion.
        extensions: List of allowed file extensions.
    
    Returns:
        Selected save path, or None if cancelled.
    """
    picker = _ensure_picker(page)
    try:
        file_type = ft.FilePickerFileType.CUSTOM if extensions else ft.FilePickerFileType.ANY
        path = await picker.save_file(
            dialog_title=title,
            file_name=default_name,
            allowed_extensions=extensions,
            file_type=file_type,
        )
        return path
    except Exception as e:
        logger.error("FilePicker.save_file failed: %s", e)
        return None
