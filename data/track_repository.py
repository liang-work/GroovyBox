import asyncio
import os
from typing import List, Optional
import threading
from data.db import get_connection
from logic.logger import logger
from data.models import Track
from logic.metadata_service import get_metadata, SUPPORTED_EXTENSIONS

AUDIO_EXTENSIONS = {"mp3", "m4a", "wav", "flac", "aac", "ogg", "wma", "m4p", "aiff", "au", "dss"}
LYRICS_EXTENSIONS = {"lrc", "srt", "txt"}


def watch_all_tracks() -> List[Track]:
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM tracks ORDER BY title COLLATE NOCASE"
    ).fetchall()
    conn.close()
    return [_row_to_track(r) for r in rows]


def get_track(track_id: int) -> Optional[Track]:
    conn = get_connection()
    row = conn.execute("SELECT * FROM tracks WHERE id = ?", (track_id,)).fetchone()
    conn.close()
    return _row_to_track(row) if row else None


def get_track_by_path(path: str) -> Optional[Track]:
    conn = get_connection()
    row = conn.execute("SELECT * FROM tracks WHERE path = ?", (path,)).fetchone()
    conn.close()
    return _row_to_track(row) if row else None


def import_files(file_paths: List[str], callback=None):
    def _import():
        try:
            conn = get_connection()
            existing = {
                r["path"] for r in conn.execute(
                    "SELECT path FROM tracks WHERE path IN ({})".format(
                        ",".join("?" * len(file_paths))
                    ), file_paths
                ).fetchall()
            }
            new_paths = [p for p in file_paths if p not in existing]
            art_dir = os.path.join(os.path.expanduser("~"), ".groovybox", "art")
            os.makedirs(art_dir, exist_ok=True)
            imported = 0
            for path in new_paths:
                if not os.path.isfile(path):
                    continue
                try:
                    meta = get_metadata(path)
                    filename = os.path.basename(path)
                    title = meta.title or os.path.splitext(filename)[0]

                    art_path = None
                    if meta.art_bytes:
                        art_name = f"{os.path.splitext(filename)[0]}_{imported}_art.jpg"
                        art_file = os.path.join(art_dir, art_name)
                        try:
                            with open(art_file, "wb") as f:
                                f.write(meta.art_bytes)
                            art_path = art_file
                        except Exception:
                            pass

                    conn.execute(
                        """INSERT OR IGNORE INTO tracks
                           (title, artist, album, duration, path, art_uri, lyrics_offset)
                           VALUES (?, ?, ?, ?, ?, ?, 0)""",
                        (title, meta.artist, meta.album,
                         meta.duration, path, art_path),
                    )
                    conn.commit()
                    imported += 1
                except Exception:
                    continue
            conn.close()
            logger.info("import_files: imported %d/%d files", imported, len(new_paths))
            if callback:
                callback()
        except Exception as e:
            logger.error("import_files thread failed: %s", e)

    threading.Thread(target=_import, daemon=True).start()


async def import_files_async(file_paths: List[str]) -> int:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _import_sync, file_paths)


def _import_sync(file_paths: List[str]) -> int:
    conn = get_connection()
    existing = {
        r["path"] for r in conn.execute(
            "SELECT path FROM tracks WHERE path IN ({})".format(
                ",".join("?" * len(file_paths))
            ), file_paths
        ).fetchall()
    }
    new_paths = [p for p in file_paths if p not in existing]
    art_dir = os.path.join(os.path.expanduser("~"), ".groovybox", "art")
    os.makedirs(art_dir, exist_ok=True)
    imported = 0
    for path in new_paths:
        if not os.path.isfile(path):
            continue
        try:
            meta = get_metadata(path)
            filename = os.path.basename(path)
            title = meta.title or os.path.splitext(filename)[0]
            art_path = None
            if meta.art_bytes:
                art_name = f"{os.path.splitext(filename)[0]}_{imported}_art.jpg"
                art_file = os.path.join(art_dir, art_name)
                try:
                    with open(art_file, "wb") as f:
                        f.write(meta.art_bytes)
                    art_path = art_file
                except Exception:
                    pass
            conn.execute(
                """INSERT OR IGNORE INTO tracks
                   (title, artist, album, duration, path, art_uri, lyrics_offset)
                   VALUES (?, ?, ?, ?, ?, ?, 0)""",
                (title, meta.artist, meta.album,
                 meta.duration, path, art_path),
            )
            conn.commit()
            imported += 1
        except Exception:
            continue
    conn.close()
    logger.info("import_files_async: imported %d/%d files", imported, len(new_paths))
    return imported


def scan_directory(directory_path: str, recursive: bool = True, callback=None):
    def _scan():
        music_files = []
        if recursive:
            for root, dirs, files in os.walk(directory_path):
                for f in files:
                    ext = os.path.splitext(f)[1].lower()
                    if ext in SUPPORTED_EXTENSIONS:
                        music_files.append(os.path.join(root, f))
        else:
            for f in os.listdir(directory_path):
                full = os.path.join(directory_path, f)
                if os.path.isfile(full):
                    ext = os.path.splitext(f)[1].lower()
                    if ext in SUPPORTED_EXTENSIONS:
                        music_files.append(full)
        if music_files:
            import_files(music_files, callback=callback)
        elif callback:
            callback()
    threading.Thread(target=_scan, daemon=True).start()


async def scan_directory_async(directory_path: str, recursive: bool = True) -> int:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _scan_sync, directory_path, recursive)


def _scan_sync(directory_path: str, recursive: bool) -> int:
    music_files = []
    if recursive:
        for root, dirs, files in os.walk(directory_path):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in SUPPORTED_EXTENSIONS:
                    music_files.append(os.path.join(root, f))
    else:
        for f in os.listdir(directory_path):
            full = os.path.join(directory_path, f)
            if os.path.isfile(full):
                ext = os.path.splitext(f)[1].lower()
                if ext in SUPPORTED_EXTENSIONS:
                    music_files.append(full)
    if music_files:
        return _import_sync(music_files)
    return 0


def update_metadata(track_id: int, title: str, artist: str = None, album: str = None):
    conn = get_connection()
    conn.execute(
        "UPDATE tracks SET title=?, artist=?, album=? WHERE id=?",
        (title, artist, album, track_id),
    )
    conn.commit()
    conn.close()


def update_lyrics(track_id: int, lyrics_json: Optional[str]):
    conn = get_connection()
    conn.execute("UPDATE tracks SET lyrics=? WHERE id=?", (lyrics_json, track_id))
    conn.commit()
    conn.close()


def update_lyrics_offset(track_id: int, offset: int):
    conn = get_connection()
    conn.execute("UPDATE tracks SET lyrics_offset=? WHERE id=?", (offset, track_id))
    conn.commit()
    conn.close()


def delete_track(track_id: int):
    conn = get_connection()
    track = conn.execute("SELECT * FROM tracks WHERE id=?", (track_id,)).fetchone()
    if track:
        art = track["art_uri"]
        if art and os.path.isfile(art):
            try:
                os.remove(art)
            except Exception:
                pass
    conn.execute("DELETE FROM tracks WHERE id=?", (track_id,))
    conn.commit()
    conn.close()


def clear_all_tracks():
    art_dir = os.path.join(os.path.expanduser("~"), ".groovybox", "art")
    if os.path.isdir(art_dir):
        for f in os.listdir(art_dir):
            try:
                os.remove(os.path.join(art_dir, f))
            except Exception:
                pass
    conn = get_connection()
    conn.execute("DELETE FROM tracks")
    conn.commit()
    conn.close()


def _row_to_track(row) -> Track:
    return Track(
        id=row["id"],
        title=row["title"],
        artist=row["artist"],
        album=row["album"],
        duration=row["duration"],
        path=row["path"],
        art_uri=row["art_uri"],
        lyrics=row["lyrics"],
        lyrics_offset=row["lyrics_offset"],
        added_at=row["added_at"],
    )
