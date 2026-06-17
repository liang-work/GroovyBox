import logging
from typing import Optional, List

import flet as ft

logger = logging.getLogger("flet")


async def pick_files(
    title: str = "Select files",
    extensions: Optional[List[str]] = None,
    allow_multiple: bool = True,
) -> Optional[List[str]]:
    try:
        file_type = ft.FilePickerFileType.CUSTOM if extensions else ft.FilePickerFileType.ANY
        result = await ft.FilePicker().pick_files(
            dialog_title=title,
            allowed_extensions=extensions,
            allow_multiple=allow_multiple,
            file_type=file_type,
        )
        if result is None:
            return None
        return [f.path for f in result if f.path]
    except Exception as e:
        logger.error("FilePicker.pick_files failed: %s", e)
        return None


async def pick_directory(title: str = "Select folder") -> Optional[str]:
    try:
        path = await ft.FilePicker().get_directory_path(dialog_title=title)
        return path
    except Exception as e:
        logger.warning("FilePicker.get_directory_path failed: %s", e)
        return None


async def save_file(
    title: str = "Save file",
    default_name: str = "file",
    extensions: Optional[List[str]] = None,
) -> Optional[str]:
    try:
        file_type = ft.FilePickerFileType.CUSTOM if extensions else ft.FilePickerFileType.ANY
        path = await ft.FilePicker().save_file(
            dialog_title=title,
            file_name=default_name,
            allowed_extensions=extensions,
            file_type=file_type,
        )
        return path
    except Exception as e:
        logger.error("FilePicker.save_file failed: %s", e)
        return None
