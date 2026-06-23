import sqlite3
import os
import json
from typing import Optional, Any


DB_PATH = None


def _is_mobile() -> bool:
    return "ANDROID_ROOT" in os.environ or os.environ.get("FLET_APP_DATA_DIR") is not None


def get_app_data_dir() -> str:
    """Return a writable app data directory on all platforms."""
    if "ANDROID_ROOT" in os.environ:
        return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if os.environ.get("FLET_APP_DATA_DIR"):
        return os.environ["FLET_APP_DATA_DIR"]
    return os.path.expanduser("~")


def get_app_dir() -> str:
    """Return the full path to the groovybox data directory."""
    base = get_app_data_dir()
    name = "groovybox" if _is_mobile() else ".groovybox"
    return os.path.join(base, name)


def get_db_path():
    global DB_PATH
    if DB_PATH is None:
        app_dir = get_app_dir()
        os.makedirs(app_dir, exist_ok=True)
        DB_PATH = os.path.join(app_dir, "groovybox.db")
    return DB_PATH


def get_connection():
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA encoding='UTF-8'")
    conn.text_factory = str
    return conn


def init_database():
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
    conn = get_connection()
    row = conn.execute("SELECT value FROM app_settings WHERE key = ?", (key,)).fetchone()
    conn.close()
    if row:
        return row["value"]
    return default


def set_setting(key: str, value: str):
    conn = get_connection()
    conn.execute(
        "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
        (key, value),
    )
    conn.commit()
    conn.close()
