import flet as ft
import flet_audio
import threading
import random
import asyncio
from typing import Optional, Callable, List
from data.models import Track, CurrentTrackData


class AudioPlayer:
    def __init__(self, page: ft.Page):
        self.page = page
        self.queue: List[Track] = []
        self.current_index = -1
        self.shuffle = False
        self.repeat_mode = "none"
        self._volume = 0.8
        self._is_playing = False
        self._position_ms = 0
        self._duration_ms = 0
        self._loading = False

        self.on_track_change: Optional[Callable] = None
        self.on_position_change: Optional[Callable] = None
        self.on_play_state_change: Optional[Callable] = None
        self.on_queue_change: Optional[Callable] = None
        self.on_loading_change: Optional[Callable] = None

        self.audio = None  # Will be created lazily (flet_audio.Audio blocks FilePicker if created too early)
        self._timer_active = False
        self._start_position_poll()

    def _start_position_poll(self):
        def poll():
            import time
            while self._timer_active:
                if self._is_playing and self.audio is not None:
                    try:
                        pos = self.audio.get_current_position()
                        if pos is not None:
                            self._position_ms = pos.in_milliseconds
                            if self.on_position_change:
                                self.on_position_change(pos.in_milliseconds)
                    except Exception:
                        pass
                time.sleep(0.25)
        self._timer_active = True
        t = threading.Thread(target=poll, daemon=True)
        t.start()

    def stop_timer(self):
        self._timer_active = False

    def _ensure_audio(self):
        if self.audio is None:
            self.audio = flet_audio.Audio(
                autoplay=False,
                volume=self._volume,
                balance=0,
                on_loaded=self._on_loaded,
                on_duration_change=self._on_duration_changed,
                on_position_change=self._on_position_changed,
                on_state_change=self._on_state_changed,
            )
            self.page.overlay.append(self.audio)
            self.page._services.register_service(self.audio)
            self.page.update()

    def _on_loaded(self, e):
        pass

    def _on_duration_changed(self, e):
        try:
            self._duration_ms = e.duration.in_milliseconds
        except (ValueError, TypeError):
            pass

    def _on_position_changed(self, e):
        try:
            self._position_ms = e.position
        except (ValueError, TypeError):
            pass
        if self.on_position_change:
            self.on_position_change(self._position_ms)

    def _on_state_changed(self, e):
        state = e.state
        if state == flet_audio.AudioState.COMPLETED:
            self._on_track_ended()
        elif state == flet_audio.AudioState.PLAYING:
            self._is_playing = True
            self._loading = False
            if self.on_loading_change:
                self.on_loading_change(False)
            if self.on_play_state_change:
                self.on_play_state_change(True)
        elif state == flet_audio.AudioState.PAUSED:
            self._is_playing = False
            if self.on_play_state_change:
                self.on_play_state_change(False)
        elif state == flet_audio.AudioState.STOPPED:
            self._is_playing = False
            if self.on_play_state_change:
                self.on_play_state_change(False)

    def _on_track_ended(self):
        if self.repeat_mode == "one":
            self.play_current()
        elif self.current_index < len(self.queue) - 1:
            self.next()
        elif self.repeat_mode == "all" and self.queue:
            self.current_index = 0
            asyncio.create_task(self._load_current_async())
        else:
            self._is_playing = False
            if self.on_play_state_change:
                self.on_play_state_change(False)
            if self.on_loading_change:
                self.on_loading_change(False)

    def play_track(self, track: Track):
        self.queue = [track]
        self.current_index = 0
        asyncio.create_task(self._load_current_async())

    def play_tracks(self, tracks: List[Track], initial_index: int = 0):
        if not tracks:
            return
        self.queue = list(tracks)
        self.current_index = initial_index
        asyncio.create_task(self._load_current_async())

    async def _load_current_async(self):
        if self.current_index < 0 or self.current_index >= len(self.queue):
            return
        track = self.queue[self.current_index]
        self._loading = True
        if self.on_loading_change:
            self.on_loading_change(True)
        self._ensure_audio()
        self.audio.source = track.path
        await asyncio.sleep(0.05)
        await self.audio.play()

        if self.on_track_change:
            self.on_track_change(CurrentTrackData(
                id=track.id,
                title=track.title,
                artist=track.artist,
                album=track.album,
                path=track.path,
                art_uri=track.art_uri,
                lyrics=track.lyrics,
                lyrics_offset=track.lyrics_offset,
            ))
        if self.on_queue_change:
            self.on_queue_change()

    def play_current(self):
        if self.current_index >= 0 and self.current_index < len(self.queue):
            self._ensure_audio()
            asyncio.create_task(self.audio.seek(0))
            asyncio.create_task(self.audio.resume())

    def toggle_play_pause(self):
        self._ensure_audio()
        if self._is_playing:
            asyncio.create_task(self.audio.pause())
        else:
            if self.current_index >= 0 and self.current_index < len(self.queue):
                asyncio.create_task(self.audio.resume())
            elif self.queue:
                asyncio.create_task(self._load_current_async())

    def next(self):
        if not self.queue:
            return
        if self.shuffle:
            self.current_index = random.randrange(0, len(self.queue))
        else:
            self.current_index += 1
        if self.current_index >= len(self.queue):
            if self.repeat_mode == "all" and self.queue:
                self.current_index = 0
            else:
                self.current_index = len(self.queue) - 1
                self._is_playing = False
                if self.on_play_state_change:
                    self.on_play_state_change(False)
                return
        asyncio.create_task(self._load_current_async())

    def previous(self):
        if not self.queue:
            return
        self.current_index -= 1
        if self.current_index < 0:
            self.current_index = 0
        asyncio.create_task(self._load_current_async())

    def seek(self, position_ms: int):
        self._ensure_audio()
        asyncio.create_task(self.audio.seek(position_ms))

    def set_volume(self, volume: float):
        self._volume = max(0.0, min(1.0, volume))
        self._ensure_audio()
        self.audio.volume = self._volume

    def get_current_track(self) -> Optional[Track]:
        if 0 <= self.current_index < len(self.queue):
            return self.queue[self.current_index]
        return None

    @property
    def is_playing(self) -> bool:
        return self._is_playing

    @property
    def position_ms(self) -> int:
        return self._position_ms

    @property
    def duration_ms(self) -> int:
        return self._duration_ms

    @property
    def volume(self) -> float:
        return self._volume

    @property
    def loading(self) -> bool:
        return self._loading
