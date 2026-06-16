import os
import tempfile
import zipfile
from typing import List, Tuple
from data.track_repository import AUDIO_EXTENSIONS, LYRICS_EXTENSIONS


PLAYLIST_EXTENSIONS = {"m3u", "m3u8", "pls"}


def extract_zip(zip_path: str, dest_dir: str = None) -> Tuple[List[str], List[str], List[str]]:
    if dest_dir is None:
        dest_dir = tempfile.mkdtemp(prefix="groovybox_zip_")
    audio_files = []
    lyrics_files = []
    playlist_files = []

    with zipfile.ZipFile(zip_path, "r") as zf:
        for info in zf.infolist():
            if info.is_dir():
                continue
            fn = info.filename
            ext = os.path.splitext(fn)[1].lower().lstrip(".")
            out_path = os.path.join(dest_dir, fn)
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            try:
                zf.extract(info, dest_dir)
            except Exception:
                continue
            if ext in AUDIO_EXTENSIONS:
                audio_files.append(out_path)
            elif ext in LYRICS_EXTENSIONS:
                lyrics_files.append(out_path)
            elif ext in PLAYLIST_EXTENSIONS:
                playlist_files.append(out_path)

    return audio_files, lyrics_files, playlist_files
