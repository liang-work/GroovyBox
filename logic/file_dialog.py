import asyncio
import concurrent.futures
from typing import Optional, List

_pool = concurrent.futures.ThreadPoolExecutor(max_workers=1)


def _pick_files_sync(title: str, extensions: List[str]) -> Optional[List[str]]:
    import tkinter as tk
    from tkinter import filedialog
    root = tk.Tk()
    root.withdraw()
    filetypes = [("Supported files", " ".join(f"*.{e}" for e in extensions))]
    files = filedialog.askopenfilenames(title=title, filetypes=filetypes)
    root.destroy()
    return list(files) if files else None


def _pick_directory_sync(title: str) -> Optional[str]:
    import tkinter as tk
    from tkinter import filedialog
    root = tk.Tk()
    root.withdraw()
    path = filedialog.askdirectory(title=title)
    root.destroy()
    return path if path else None


def _save_file_sync(title: str, default_name: str, extensions: List[str]) -> Optional[str]:
    import tkinter as tk
    from tkinter import filedialog
    root = tk.Tk()
    root.withdraw()
    filetypes = [("Supported files", " ".join(f"*.{e}" for e in extensions))]
    path = filedialog.asksaveasfilename(
        title=title,
        defaultextension=f".{extensions[0]}" if extensions else "",
        filetypes=filetypes,
        initialfile=default_name,
    )
    root.destroy()
    return path if path else None


async def pick_files(title: str = "Select files", extensions: Optional[List[str]] = None) -> Optional[List[str]]:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_pool, _pick_files_sync, title, extensions or [])


async def pick_directory(title: str = "Select folder") -> Optional[str]:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_pool, _pick_directory_sync, title)


async def save_file(title: str = "Save file", default_name: str = "file", extensions: Optional[List[str]] = None) -> Optional[str]:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(_pool, _save_file_sync, title, default_name, extensions or [])