"""Track Repository for GroovyBox.

This module provides CRUD operations for music tracks in the database.
Handles file import, metadata extraction, album art storage, directory
scanning, and track management operations. Supports both synchronous
(threaded) and asynchronous import workflows.
"""

import asyncio
import os
from typing import List, Optional
import threading
from data.db import get_connection, get_app_dir
from logic.logger import logger
from data.models import Track
from logic.metadata_service import get_metadata, SUPPORTED_EXTENSIONS

# Supported audio file extensions for import
AUDIO_EXTENSIONS = {"mp3", "m4a", "wav", "flac", "aac", "ogg", "wma", "m4p", "aiff", "au", "dss"}

# Supported lyrics file extensions for batch import
LYRICS_EXTENSIONS = {"lrc", "srt", "txt"}


def watch_all_tracks() -> List[Track]:
    """Retrieve all tracks from the database, sorted alphabetically by title.
    
    Returns:
        List of Track objects ordered by title (case-insensitive).
    """
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM tracks ORDER BY title COLLATE NOCASE"
    ).fetchall()
    conn.close()
    return [_row_to_track(r) for r in rows]


def get_track(track_id: int) -> Optional[Track]:
    """Retrieve a single track by its database ID.
    
    Args:
        track_id: The unique database identifier.
    
    Returns:
        Track object if found, None otherwise.
    """
    conn = get_connection()
    row = conn.execute("SELECT * FROM tracks WHERE id = ?", (track_id,)).fetchone()
    conn.close()
    return _row_to_track(row) if row else None


def get_track_by_path(path: str) -> Optional[Track]:
    """Retrieve a track by its file path.
    
    Args:
        path: The absolute file path of the audio file.
    
    Returns:
        Track object if found, None otherwise.
    """
    conn = get_connection()
    row = conn.execute("SELECT * FROM tracks WHERE path = ?", (path,)).fetchone()
    conn.close()
    return _row_to_track(row) if row else None


def import_files(file_paths: List[str], callback=None):
    """Import audio files into the database in a background thread.
    
    Skips files that already exist in the database. Extracts metadata
    and saves album art to the app's art directory.
    
    Args:
        file_paths: List of absolute paths to audio files.
        callback: Optional function called after import completes.
    """
    def _import():
        try:
            conn = get_connection()
            # Check which files already exist in the database
            existing = {
                r["path"] for r in conn.execute(
                    "SELECT path FROM tracks WHERE path IN ({})".format(
                        ",".join("?" * len(file_paths))
                    ), file_paths
                ).fetchall()
            }
            new_paths = [p for p in file_paths if p not in existing]
            
            # Create art storage directory
            art_dir = os.path.join(get_app_dir(), "art")
            os.makedirs(art_dir, exist_ok=True)
            
            imported = 0
            for path in new_paths:
                if not os.path.isfile(path):
                    continue
                try:
                    # Extract metadata from the audio file
                    meta = get_metadata(path)
                    filename = os.path.basename(path)
                    title = meta.title or os.path.splitext(filename)[0]

                    # Save album art to disk if available
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

                    # Insert track record into the database
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
    """Import audio files asynchronously using a thread executor.
    
    Args:
        file_paths: List of absolute paths to audio files.
    
    Returns:
        Number of files successfully imported.
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _import_sync, file_paths)


def _import_sync(file_paths: List[str]) -> int:
    """Synchronous import implementation for use with thread executor.
    
    Args:
        file_paths: List of absolute paths to audio files.
    
    Returns:
        Number of files successfully imported.
    """
    conn = get_connection()
    # Check for existing files
    existing = {
        r["path"] for r in conn.execute(
            "SELECT path FROM tracks WHERE path IN ({})".format(
                ",".join("?" * len(file_paths))
            ), file_paths
        ).fetchall()
    }
    new_paths = [p for p in file_paths if p not in existing]
    
    # Create art storage directory
    art_dir = os.path.join(get_app_dir(), "art")
    os.makedirs(art_dir, exist_ok=True)
    
    imported = 0
    for path in new_paths:
        if not os.path.isfile(path):
            continue
        try:
            meta = get_metadata(path)
            filename = os.path.basename(path)
            title = meta.title or os.path.splitext(filename)[0]
            
            # Save album art
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
    """Scan a directory for audio files and import them in a background thread.
    
    Args:
        directory_path: Absolute path to the directory to scan.
        recursive: Whether to scan subdirectories recursively.
        callback: Optional function called after scan completes.
    """
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
    """Scan a directory for audio files asynchronously.
    
    Args:
        directory_path: Absolute path to the directory to scan.
        recursive: Whether to scan subdirectories recursively.
    
    Returns:
        Number of audio files found and imported.
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _scan_sync, directory_path, recursive)


def _scan_sync(directory_path: str, recursive: bool) -> int:
    """Synchronous directory scan implementation.
    
    Args:
        directory_path: Absolute path to the directory to scan.
        recursive: Whether to scan subdirectories recursively.
    
    Returns:
        Number of audio files found and imported.
    """
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
    """Update a track's metadata in the database.
    
    Args:
        track_id: The track's database ID.
        title: New title value.
        artist: New artist value (optional).
        album: New album value (optional).
    """
    conn = get_connection()
    conn.execute(
        "UPDATE tracks SET title=?, artist=?, album=? WHERE id=?",
        (title, artist, album, track_id),
    )
    conn.commit()
    conn.close()


def update_lyrics(track_id: int, lyrics_json: Optional[str]):
    """Update a track's lyrics data in the database.
    
    Args:
        track_id: The track's database ID.
        lyrics_json: JSON string containing lyrics data, or None to clear.
    """
    conn = get_connection()
    conn.execute("UPDATE tracks SET lyrics=? WHERE id=?", (lyrics_json, track_id))
    conn.commit()
    conn.close()


def update_lyrics_offset(track_id: int, offset: int):
    """Update a track's lyrics synchronization offset.
    
    Args:
        track_id: The track's database ID.
        offset: New offset value in milliseconds.
    """
    conn = get_connection()
    conn.execute("UPDATE tracks SET lyrics_offset=? WHERE id=?", (offset, track_id))
    conn.commit()
    conn.close()


def delete_track(track_id: int):
    """Delete a track from the database and remove its album art file.
    
    Args:
        track_id: The track's database ID.
    """
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
    """Delete all tracks from the database and clear the album art directory.
    
    This is a destructive operation used for database reset.
    """
    # Remove all album art files
    art_dir = os.path.join(get_app_dir(), "art")
    if os.path.isdir(art_dir):
        for f in os.listdir(art_dir):
            try:
                os.remove(os.path.join(art_dir, f))
            except Exception:
                pass
    # Clear all track records
    conn = get_connection()
    conn.execute("DELETE FROM tracks")
    conn.commit()
    conn.close()


def _row_to_track(row) -> Track:
    """Convert a database row to a Track dataclass instance.
    
    Args:
        row: A sqlite3.Row object from a tracks table query.
    
    Returns:
        A Track instance with values from the row.
    """
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
