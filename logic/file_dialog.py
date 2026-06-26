"""File Dialog Module for GroovyBox.

This module provides wrapper functions for Flet's FilePicker,
offering a simplified API for common file operations: picking files,
selecting directories, and saving files. Handles platform-specific
error cases gracefully.

Note: FilePicker is a Service (not a visual Control) in Flet 0.85+.
Service.init() auto-registers with page._services, so it must NOT
be added to page.overlay.
"""

import logging
from typing import Optional, List

from flet import FilePicker
from flet import FilePickerFileType

logger = logging.getLogger("flet")


async def pick_files(
    page,
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
    try:
        picker = FilePicker()
        file_type = FilePickerFileType.CUSTOM if extensions else FilePickerFileType.ANY
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
    page,
    title: str = "Select folder",
) -> Optional[str]:
    """Open a directory picker dialog.

    Args:
        page: The Flet page instance.
        title: Dialog window title.

    Returns:
        Selected directory path, or None if cancelled.
    """
    try:
        picker = FilePicker()
        return await picker.get_directory_path(dialog_title=title)
    except Exception as e:
        logger.warning("FilePicker.get_directory_path failed: %s", e)
        return None


async def save_file(
    page,
    title: str = "Save file",
    default_name: str = "file",
    extensions: Optional[List[str]] = None,
) -> Optional[str]:
    """Open a save file dialog.

    On iOS/Android, src_bytes is required; this function does not
    currently support saving from raw bytes — returns None on mobile.

    Args:
        page: The Flet page instance.
        title: Dialog window title.
        default_name: Default filename suggestion.
        extensions: List of allowed file extensions.

    Returns:
        Selected save path, or None if cancelled / unsupported on mobile.
    """
    try:
        picker = FilePicker()
        file_type = FilePickerFileType.CUSTOM if extensions else FilePickerFileType.ANY
        path = await picker.save_file(
            dialog_title=title,
            file_name=default_name,
            allowed_extensions=extensions,
            file_type=file_type,
        )
        return path
    except ValueError as e:
        logger.warning("FilePicker.save_file not supported on this platform: %s", e)
        return None
    except Exception as e:
        logger.error("FilePicker.save_file failed: %s", e)
        return None
