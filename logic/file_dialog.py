import logging
from typing import Optional, List

import flet as ft

logger = logging.getLogger("flet")

_picker: Optional[ft.FilePicker] = None

def _ensure_picker(page: ft.Page) -> ft.FilePicker:
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
