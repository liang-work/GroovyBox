import os
from typing import Optional
from mutagen import File as MutagenFile
from mutagen.mp3 import MP3
from mutagen.flac import FLAC
from mutagen.oggvorbis import OggVorbis
from mutagen.mp4 import MP4
from mutagen.apev2 import APEv2File
from data.models import TrackMetadata


SUPPORTED_EXTENSIONS = {
    '.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg', '.wma', '.opus', '.aiff',
}


def get_metadata(file_path: str) -> TrackMetadata:
    meta = TrackMetadata()
    if not os.path.isfile(file_path):
        return meta

    try:
        audio = MutagenFile(file_path)
        if audio is None:
            return meta

        # Title
        meta.title = _safe_tag(audio, "title")

        # Artist
        meta.artist = _safe_tag(audio, "artist")

        # Album
        meta.album = _safe_tag(audio, "album")

        # Duration (seconds -> ms)
        if hasattr(audio.info, "length") and audio.info.length:
            meta.duration = int(audio.info.length * 1000)

        # Album art
        meta.art_bytes = _extract_art(audio)

    except Exception:
        pass

    return meta


def _safe_tag(audio, key: str) -> Optional[str]:
    try:
        if key in audio:
            val = audio[key]
            if isinstance(val, list) and len(val) > 0:
                return str(val[0])
            return str(val)
    except Exception:
        pass
    return None


def _extract_art(audio) -> Optional[bytes]:
    try:
        # MP3 / ID3
        if hasattr(audio, "tags") and audio.tags:
            for tag in audio.tags.values():
                if hasattr(tag, "data"):
                    return tag.data
                if hasattr(tag, "picture"):
                    return tag.picture.data

        # FLAC
        if hasattr(audio, "pictures") and audio.pictures:
            return audio.pictures[0].data

        # MP4
        if hasattr(audio, "tags") and "covr" in audio.tags:
            covr = audio.tags["covr"]
            if covr and len(covr) > 0:
                return covr[0]

    except Exception:
        pass
    return None


def format_duration(duration_ms: Optional[int]) -> str:
    if duration_ms is None:
        return "--:--"
    total_sec = duration_ms // 1000
    minutes = total_sec // 60
    seconds = total_sec % 60
    return f"{minutes}:{seconds:02d}"
