import os
import shutil
import tempfile
import zipfile
from typing import List, Optional
from data import playlist_repository as prepo
from data.models import Track, Playlist


def export_playlist(playlist_id: int, output_path: str, use_relpath: bool = False,
                    include_lyrics: bool = False, include_covers: bool = False,
                    as_zip: bool = False) -> str:
    playlist = None
    for p in prepo.watch_all_playlists():
        if p.id == playlist_id:
            playlist = p
            break
    if not playlist:
        raise ValueError(f"Playlist {playlist_id} not found")

    tracks = prepo.watch_playlist_tracks(playlist_id)
    out_dir = os.path.dirname(output_path) or "."
    base_name = os.path.splitext(os.path.basename(output_path))[0]

    if as_zip:
        return _export_as_zip(playlist, tracks, output_path, out_dir, base_name, use_relpath, include_lyrics, include_covers)
    else:
        return _export_m3u(playlist, tracks, output_path, out_dir, use_relpath, include_lyrics, include_covers)


def _export_m3u(playlist: Playlist, tracks: List[Track], output_path: str, out_dir: str,
                use_relpath: bool, include_lyrics: bool, include_covers: bool) -> str:
    lines = ["#EXTM3U"]
    for t in tracks:
        if not t.path or not os.path.isfile(t.path):
            continue
        duration_sec = (t.duration or 0) // 1000
        lines.append(f"#EXTINF:{duration_sec},{t.artist or 'Unknown'} - {t.title}")
        ref = _make_path(t.path, out_dir, use_relpath)
        lines.append(ref)

        if include_lyrics and t.lyrics:
            lyrics_path = os.path.join(out_dir, f"{t.title or 'lyrics'}.lrc")
            _write_lyrics_file(lyrics_path, t.lyrics)

        if include_covers and t.art_uri and os.path.isfile(t.art_uri):
            ext = os.path.splitext(t.art_uri)[1] or ".jpg"
            cover_dst = os.path.join(out_dir, f"{t.title or 'cover'}{ext}")
            shutil.copy2(t.art_uri, cover_dst)

    os.makedirs(out_dir, exist_ok=True)
    with open(output_path, "w", encoding="utf-8-sig") as f:
        f.write("\n".join(lines))
    return output_path


def _export_as_zip(playlist: Playlist, tracks: List[Track], output_path: str, out_dir: str, base_name: str,
                   use_relpath: bool, include_lyrics: bool, include_covers: bool) -> str:
    with tempfile.TemporaryDirectory() as tmpdir:
        inner_dir = os.path.join(tmpdir, base_name)
        os.makedirs(inner_dir, exist_ok=True)
        m3u_path = os.path.join(inner_dir, f"{base_name}.m3u")
        _export_m3u(playlist, tracks, m3u_path, inner_dir, use_relpath=False, include_lyrics=include_lyrics, include_covers=include_covers)

        for t in tracks:
            if not t.path or not os.path.isfile(t.path):
                continue
            dst = os.path.join(inner_dir, os.path.basename(t.path))
            if not os.path.exists(dst):
                try:
                    shutil.copy2(t.path, dst)
                except Exception:
                    pass

        os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
        with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(tmpdir):
                for fn in files:
                    fp = os.path.join(root, fn)
                    arcname = os.path.relpath(fp, tmpdir)
                    zf.write(fp, arcname)
    return output_path


def _make_path(file_path: str, base_dir: str, use_relpath: bool) -> str:
    if use_relpath:
        try:
            return os.path.relpath(file_path, base_dir)
        except ValueError:
            return file_path
    return os.path.abspath(file_path)


def _write_lyrics_file(path: str, lyrics_json: str):
    try:
        from logic.lyrics_parser import lyrics_from_json
        data = lyrics_from_json(lyrics_json)
        if data and data.lines:
            if data.type == "timed":
                lines_out = []
                for ln in data.lines:
                    if ln.time_ms is not None:
                        mins = (ln.time_ms // 60000) % 100
                        secs = (ln.time_ms // 1000) % 60
                        cs = (ln.time_ms % 1000) // 10
                        lines_out.append(f"[{mins:02d}:{secs:02d}.{cs:02d}]{ln.text}")
                    else:
                        lines_out.append(ln.text or "")
                with open(path, "w", encoding="utf-8") as f:
                    f.write("\n".join(lines_out))
            else:
                with open(path, "w", encoding="utf-8") as f:
                    for ln in data.lines:
                        f.write((ln.text or "") + "\n")
    except Exception:
        pass
