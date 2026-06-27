"""Playlist Repository for GroovyBox.

This module provides CRUD operations for playlists and their associated tracks.
Also includes queries for albums, artists, and artist-album relationships
used by the library browsing screens.
"""

from typing import List, Optional
from data.db import get_connection
from data.models import Track, Playlist, AlbumData, ArtistAlbums
from data.track_repository import _row_to_track


def watch_all_playlists() -> List[Playlist]:
    """Retrieve all playlists ordered by creation date.
    
    Returns:
        List of Playlist objects sorted by creation time.
    """
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM playlists ORDER BY created_at"
    ).fetchall()
    conn.close()
    return [_row_to_playlist(r) for r in rows]


def watch_playlist_tracks(playlist_id: int) -> List[Track]:
    """Retrieve all tracks in a playlist, ordered by sort_order then added_at.
    
    Args:
        playlist_id: The playlist's database ID.
    
    Returns:
        List of Track objects in the playlist.
    """
    conn = get_connection()
    rows = conn.execute(
        """SELECT t.* FROM tracks t
           JOIN playlist_entries pe ON t.id = pe.track_id
           WHERE pe.playlist_id = ?
           ORDER BY pe.sort_order, pe.added_at""",
        (playlist_id,),
    ).fetchall()
    conn.close()
    return [_row_to_track(r) for r in rows]


def set_playlist_track_order(playlist_id: int, track_ids: List[int]):
    """Update the sort_order for all tracks in a playlist.
    
    Each track gets an incrementing sort_order value based on its
    position in the provided list.
    
    Args:
        playlist_id: The playlist's database ID.
        track_ids: Track IDs in the desired order.
    """
    conn = get_connection()
    for order, tid in enumerate(track_ids):
        conn.execute(
            "UPDATE playlist_entries SET sort_order = ? WHERE playlist_id = ? AND track_id = ?",
            (order, playlist_id, tid),
        )
    conn.commit()
    conn.close()


def find_by_name(name: str) -> int | None:
    conn = get_connection()
    row = conn.execute(
        "SELECT id FROM playlists WHERE name = ?", (name,)
    ).fetchone()
    conn.close()
    return row[0] if row else None


def create_playlist(name: str) -> int:
    """Create a new playlist.
    
    Args:
        name: Display name for the new playlist.
    
    Returns:
        The database ID of the newly created playlist.
    """
    conn = get_connection()
    cur = conn.execute("INSERT INTO playlists (name) VALUES (?)", (name,))
    conn.commit()
    pid = cur.lastrowid
    conn.close()
    return pid


def delete_playlist(playlist_id: int):
    """Delete a playlist and all its entries.
    
    Playlist entries are cascade-deleted when the playlist is removed.
    
    Args:
        playlist_id: The playlist's database ID.
    """
    conn = get_connection()
    conn.execute("DELETE FROM playlists WHERE id=?", (playlist_id,))
    conn.commit()
    conn.close()


def add_to_playlist(playlist_id: int, track_id: int):
    """Add a track to a playlist.
    
    Silently ignores duplicate entries.
    
    Args:
        playlist_id: The playlist's database ID.
        track_id: The track's database ID.
    """
    conn = get_connection()
    conn.execute(
        "INSERT OR IGNORE INTO playlist_entries (playlist_id, track_id) VALUES (?, ?)",
        (playlist_id, track_id),
    )
    conn.commit()
    conn.close()


def remove_from_playlist(playlist_id: int, track_id: int):
    """Remove a track from a playlist.
    
    Args:
        playlist_id: The playlist's database ID.
        track_id: The track's database ID.
    """
    conn = get_connection()
    conn.execute(
        "DELETE FROM playlist_entries WHERE playlist_id=? AND track_id=?",
        (playlist_id, track_id),
    )
    conn.commit()
    conn.close()


def watch_artists_with_albums() -> List[ArtistAlbums]:
    """Retrieve all artists with their albums and track counts.
    
    Groups tracks by artist and album, collecting album art and
    counting tracks per artist. Used by the albums-by-artist screen.
    
    Returns:
        List of ArtistAlbums objects sorted by artist name.
    """
    conn = get_connection()
    rows = conn.execute(
        """SELECT COALESCE(NULLIF(artist,''), 'Unknown') as artist,
                  album, MIN(art_uri) as art_uri
           FROM tracks WHERE album IS NOT NULL
           GROUP BY artist, album ORDER BY artist, album"""
    ).fetchall()
    conn.close()
    
    # Group albums by artist
    artists_dict = {}
    for r in rows:
        artist_name = r["artist"]
        if artist_name not in artists_dict:
            artists_dict[artist_name] = {"albums": [], "track_count": 0}
        artists_dict[artist_name]["albums"].append(
            AlbumData(album=r["album"], artist=artist_name, art_uri=r["art_uri"])
        )
    
    # Count tracks per artist
    conn2 = get_connection()
    for artist_name, data in artists_dict.items():
        safe_name = artist_name if artist_name != "Unknown" else ""
        if safe_name:
            cnt = conn2.execute(
                "SELECT COUNT(*) as c FROM tracks WHERE artist=? AND album IS NOT NULL",
                (safe_name,)
            ).fetchone()["c"]
        else:
            cnt = conn2.execute(
                "SELECT COUNT(*) as c FROM tracks WHERE (artist IS NULL OR artist='') AND album IS NOT NULL"
            ).fetchone()["c"]
        data["track_count"] = cnt
    conn2.close()
    
    return [
        ArtistAlbums(artist=a, albums=d["albums"], track_count=d["track_count"])
        for a, d in artists_dict.items()
    ]


def watch_all_albums() -> List[AlbumData]:
    """Retrieve all albums with their primary artist and art.
    
    Returns:
        List of AlbumData objects sorted by album name.
    """
    conn = get_connection()
    rows = conn.execute(
        """SELECT album, MIN(artist) as artist, MIN(art_uri) as art_uri
           FROM tracks WHERE album IS NOT NULL
           GROUP BY album ORDER BY album"""
    ).fetchall()
    conn.close()
    return [
        AlbumData(
            album=r["album"],
            artist=r["artist"] or "Various Artists",
            art_uri=r["art_uri"],
        )
        for r in rows
    ]


def watch_artist_tracks(artist_name: str) -> List[Track]:
    """Retrieve all tracks by a specific artist.
    
    Args:
        artist_name: The artist name to filter by. Use "Unknown" for
                     tracks without an artist tag.
    
    Returns:
        List of Track objects sorted by album then title.
    """
    conn = get_connection()
    if artist_name == "Unknown":
        rows = conn.execute(
            "SELECT * FROM tracks WHERE (artist IS NULL OR artist='') ORDER BY title"
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM tracks WHERE artist=? ORDER BY album, title", (artist_name,)
        ).fetchall()
    conn.close()
    return [_row_to_track(r) for r in rows]


def watch_album_tracks(album_name: str) -> List[Track]:
    """Retrieve all tracks in a specific album.
    
    Args:
        album_name: The album name to filter by.
    
    Returns:
        List of Track objects sorted by title.
    """
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM tracks WHERE album = ? ORDER BY title", (album_name,)
    ).fetchall()
    conn.close()
    return [_row_to_track(r) for r in rows]


def _row_to_playlist(row) -> Playlist:
    """Convert a database row to a Playlist dataclass instance.
    
    Args:
        row: A sqlite3.Row object from a playlists table query.
    
    Returns:
        A Playlist instance with values from the row.
    """
    return Playlist(
        id=row["id"],
        name=row["name"],
        created_at=row["created_at"],
    )
