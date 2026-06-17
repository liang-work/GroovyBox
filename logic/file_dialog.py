import asyncio
import concurrent.futures
import logging
from typing import Optional, List

import flet as ft

logger = logging.getLogger("flet")
_pool = concurrent.futures.ThreadPoolExecutor(max_workers=1)


def _is_mobile() -> bool:
    try:
        p = ft.context.page
        return p.platform in (ft.PagePlatform.IOS, ft.PagePlatform.ANDROID, ft.PagePlatform.ANDROID_TV)
    except Exception:
        return False


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
        logger.warning("FilePicker.pick_files failed: %s", e)

    if _is_mobile():
        logger.error("FilePicker is not available on mobile, cannot pick files")
        return None

    import tkinter as tk
    from tkinter import filedialog

    def _sync():
        root = tk.Tk()
        root.withdraw()
        filetypes = [("Supported files", " ".join(f"*.{e}" for e in extensions or []))]
        files = filedialog.askopenfilenames(title=title, filetypes=filetypes)
        root.destroy()
        return list(files) if files else None

    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_pool, _sync)


async def pick_directory(title: str = "Select folder") -> Optional[str]:
    try:
        path = await ft.FilePicker().get_directory_path(dialog_title=title)
        return path
    except Exception as e:
        logger.warning("FilePicker.get_directory_path failed: %s", e)

    if _is_mobile():
        logger.info("Directory picking is not supported on mobile")
        return None

    import tkinter as tk
    from tkinter import filedialog

    def _sync():
        root = tk.Tk()
        root.withdraw()
        p = filedialog.askdirectory(title=title)
        root.destroy()
        return p if p else None

    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_pool, _sync)


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
        logger.warning("FilePicker.save_file failed: %s", e)

    if _is_mobile():
        logger.error("FilePicker is not available on mobile, cannot save file")
        return None

    import tkinter as tk
    from tkinter import filedialog

    def _sync():
        root = tk.Tk()
        root.withdraw()
        filetypes = [("Supported files", " ".join(f"*.{e}" for e in extensions or []))]
        p = filedialog.asksaveasfilename(
            title=title,
            defaultextension=f".{extensions[0]}" if extensions else "",
            filetypes=filetypes,
            initialfile=default_name,
        )
        root.destroy()
        return p if p else None

    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_pool, _sync)
