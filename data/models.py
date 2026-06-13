from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Track:
    id: int = 0
    title: str = ""
    artist: Optional[str] = None
    album: Optional[str] = None
    duration: Optional[int] = None
    path: str = ""
    art_uri: Optional[str] = None
    lyrics: Optional[str] = None
    lyrics_offset: int = 0
    added_at: str = ""


@dataclass
class Playlist:
    id: int = 0
    name: str = ""
    created_at: str = ""


@dataclass
class AlbumData:
    album: str = ""
    artist: str = ""
    art_uri: Optional[str] = None

@dataclass
class ArtistAlbums:
    artist: str = ""
    albums: list = field(default_factory=list)
    track_count: int = 0


@dataclass
class WatchFolder:
    id: int = 0
    path: str = ""
    name: str = ""
    is_active: bool = True
    recursive: bool = True
    added_at: str = ""
    last_scanned: Optional[str] = None


@dataclass
class SettingsState:
    auto_scan: bool = True
    default_player_screen: str = "cover"
    lyrics_mode: str = "auto"
    continue_plays: bool = False


@dataclass
class CurrentTrackData:
    id: int = 0
    title: str = ""
    artist: Optional[str] = None
    album: Optional[str] = None
    path: str = ""
    art_uri: Optional[str] = None
    lyrics: Optional[str] = None
    lyrics_offset: int = 0


@dataclass
class TrackMetadata:
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    art_bytes: Optional[bytes] = None


@dataclass
class LyricsLine:
    time_ms: Optional[int] = None
    text: str = ""


@dataclass
class LyricsData:
    type: str = "plain"
    lines: list = field(default_factory=list)
