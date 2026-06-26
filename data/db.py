"""Database Module for GroovyBox.

This module handles all database operations including connection management,
schema initialization, and application settings persistence. Uses SQLite
with WAL journal mode for concurrent read/write performance.
"""

import platform
import sqlite3
import os
from typing import Optional


# Global cached database path to avoid repeated path resolution
DB_PATH = None


def _is_mobile() -> bool:
    """Check if the application is running on a mobile platform.

    Returns:
        True if running on Android, iOS, or in a Flet mobile environment.
    """
    if "ANDROID_ROOT" in os.environ:
        return True
    if os.environ.get("FLET_APP_DATA_DIR"):
        return True
    if platform.system() == "iOS":
        return True
    return False


def get_app_data_dir() -> str:
    """Return a writable app data directory on all platforms.

    Resolves the appropriate base directory based on the platform:
    - Android: Application's parent directory
    - iOS: Library/Application Support (sandbox-safe, not iCloud-backed)
    - Flet mobile: FLET_APP_DATA_DIR environment variable
    - Desktop: User's home directory

    Returns:
        Absolute path to the writable application data directory.
    """
    if "ANDROID_ROOT" in os.environ:
        return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if os.environ.get("FLET_APP_DATA_DIR"):
        return os.environ["FLET_APP_DATA_DIR"]
    if platform.system() == "iOS":
        return os.path.join(os.path.expanduser("~"), "Library", "Application Support")
    return os.path.expanduser("~")


def get_app_dir() -> str:
    """Return the full path to the GroovyBox data directory.

    Creates a platform-appropriate subdirectory:
    - Mobile: "groovybox" (without dot prefix)
    - Desktop: ".groovybox" (hidden directory)

    Returns:
        Absolute path to the GroovyBox data directory.
    """
    base = get_app_data_dir()
    name = "groovybox" if _is_mobile() else ".groovybox"
    return os.path.join(base, name)


def get_db_path():
    """Get the path to the SQLite database file.
    
    Creates the data directory if it doesn't exist. Caches the path
    in the global DB_PATH variable for subsequent calls.
    
    Returns:
        Absolute path to the groovybox.db database file.
    """
    global DB_PATH
    if DB_PATH is None:
        app_dir = get_app_dir()
        os.makedirs(app_dir, exist_ok=True)
        DB_PATH = os.path.join(app_dir, "groovybox.db")
    return DB_PATH


def get_connection():
    """Create and configure a new SQLite database connection.
    
    Configures the connection with:
    - Row factory for dict-like access to query results
    - WAL journal mode for better concurrent access
    - Foreign key enforcement
    - UTF-8 encoding
    
    Returns:
        A configured sqlite3.Connection instance.
    """
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA encoding='UTF-8'")
    conn.text_factory = str
    return conn


def init_database():
    """Initialize the database schema.
    
    Creates all required tables if they don't exist:
    - tracks: Music track library
    - playlists: User-created playlists
    - playlist_entries: Many-to-many relationship between playlists and tracks
    - watch_folders: Monitored music library folders
    - app_settings: Key-value store for application preferences
    """
    conn = get_connection()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            duration INTEGER,
            path TEXT UNIQUE NOT NULL,
            art_uri TEXT,
            lyrics TEXT,
            lyrics_offset INTEGER DEFAULT 0,
            added_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS playlist_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER REFERENCES playlists(id) ON DELETE CASCADE,
            track_id INTEGER REFERENCES tracks(id) ON DELETE CASCADE,
            added_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS watch_folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            recursive INTEGER DEFAULT 1,
            added_at TEXT DEFAULT (datetime('now')),
            last_scanned TEXT
        );

        CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
    """)
    conn.commit()
    conn.close()


# --- Settings helpers ---

def get_setting(key: str, default: str = "") -> str:
    """Retrieve an application setting value.
    
    Args:
        key: The setting key to look up.
        default: Default value if the key doesn't exist.
    
    Returns:
        The setting value as a string, or the default if not found.
    """
    conn = get_connection()
    row = conn.execute("SELECT value FROM app_settings WHERE key = ?", (key,)).fetchone()
    conn.close()
    if row:
        return row["value"]
    return default


def set_setting(key: str, value: str):
    """Save an application setting value.
    
    Creates the setting if it doesn't exist, or updates it if it does.
    
    Args:
        key: The setting key to save.
        value: The string value to store.
    """
    conn = get_connection()
    conn.execute(
        "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
        (key, value),
    )
    conn.commit()
    conn.close()
