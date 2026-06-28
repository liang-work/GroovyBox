"""Audio Handler for GroovyBox.

This module provides the AudioPlayer class that manages audio playback
across different platforms. Supports two backends:
- Pygame: For desktop platforms (Windows, Linux, macOS)
- flet_audio: For mobile platforms (Android, iOS)

The player handles track queue management, playback controls, position
tracking, and cross-thread UI updates via callbacks.
"""

import threading
import queue
import asyncio
import os
from data import db
import time
import random
from typing import Optional, Callable, List
import flet as ft
from data.models import Track, CurrentTrackData
from logic.logger import logger


class AudioPlayer:
    """Core audio playback engine for GroovyBox.
    
    Manages a queue of tracks, handles play/pause/seek operations,
    and provides real-time position updates to the UI. Automatically
    selects the appropriate audio backend based on the platform.
    
    Attributes:
        queue: List of Track objects in the playback queue.
        current_index: Index of the currently playing track in the queue.
        shuffle: Whether shuffle mode is enabled.
        repeat_mode: Current repeat mode ("none", "one", or "all").
    """

    def __init__(self, page: ft.Page):
        self.page = page
        self.queue: List[Track] = []
        self.current_index = -1
        self.shuffle = False
        self.repeat_mode = "none"
        self._volume = float(db.get_setting("player_volume", "0.8"))
        self._is_playing = False
        self._position_ms = 0
        self._duration_ms = 0
        self._loading = False

        # UI event loop reference for thread-safe callbacks
        self._ui_loop: Optional[asyncio.AbstractEventLoop] = None

        # Callback functions for UI updates
        self.on_track_change: Optional[Callable] = None
        self.on_position_change: Optional[Callable] = None
        self.on_play_state_change: Optional[Callable] = None
        self.on_queue_change: Optional[Callable] = None
        self.on_loading_change: Optional[Callable] = None

        # Select audio backend based on platform
        self._is_desktop_platform = self._is_desktop()
        self._use_pygame = self._is_desktop_platform
        if self._use_pygame:
            self._init_pygame()
        else:
            try:
                self._init_flet_audio()
            except Exception as ex:
                logger.warning(f"flet_audio init failed ({ex})")
                self._init_noop()

    # --- Platform detection ---

    def _is_desktop(self):
        """Check if running on a desktop platform.
        
        Returns:
            True if on Windows, Linux, or macOS; False for mobile.
        """
        try:
            p = self.page.platform
            return p in (ft.PagePlatform.WINDOWS, ft.PagePlatform.LINUX, ft.PagePlatform.MACOS)
        except Exception:
            return True

    # ======================== Pygame backend ========================

    def _init_pygame(self):
        """Initialize the Pygame mixer for desktop audio playback.
        
        Sets up a worker thread for audio commands and a polling thread
        for position tracking and track-end detection.
        """
        import pygame
        pygame.mixer.init(frequency=44100, size=-16, channels=2)
        logger.debug("Pygame mixer initialized")

        # Command queue for thread-safe audio operations
        self._cmd_queue: queue.Queue = queue.Queue()
        self._worker = threading.Thread(target=self._pygame_worker, daemon=True)
        self._worker.start()
        logger.debug("Audio worker thread started")

        # Position tracking state
        self._seek_base_ms = 0
        self._was_busy = False
        self._timer_active = True
        self._pending_cmd = False
        self._poll_thread = threading.Thread(target=self._pygame_poll, daemon=True)
        self._poll_thread.start()

    def _pygame_worker(self):
        """Worker thread that processes audio commands from the queue.
        
        Handles load, play, pause, resume, seek, and volume commands.
        Deduplicates consecutive seek commands for efficiency.
        """
        import pygame
        while True:
            cmd, args = self._cmd_queue.get()
            if cmd == "quit":
                break
            
            # Deduplicate consecutive seek commands
            if cmd == "seek":
                while True:
                    try:
                        next_cmd, next_args = self._cmd_queue.get_nowait()
                        if next_cmd == "seek":
                            cmd, args = next_cmd, next_args
                            continue
                        self._cmd_queue.put((next_cmd, next_args))
                    except queue.Empty:
                        break
                    break
            
            try:
                if cmd == "load_play":
                    path = args[0]
                    try:
                        pygame.mixer.music.load(path)
                    except pygame.error:
                        f = open(path, "rb")
                        pygame.mixer.music.load(f)
                        f.close()
                    pygame.mixer.music.set_volume(self._volume)
                    pygame.mixer.music.play()
                elif cmd == "pause":
                    pygame.mixer.music.pause()
                elif cmd == "resume":
                    pygame.mixer.music.unpause()
                elif cmd == "seek":
                    pos_ms = args[0]
                    pygame.mixer.music.play(start=pos_ms / 1000.0)
                    pygame.mixer.music.set_volume(self._volume)
                elif cmd == "set_volume":
                    pygame.mixer.music.set_volume(args[0])
            except Exception as ex:
                logger.error(f"Audio worker error: {ex}")
            finally:
                if cmd in ("load_play", "seek"):
                    self._pending_cmd = False
            self._cmd_queue.task_done()

    def _pygame_send(self, cmd, *args):
        """Send a command to the Pygame audio worker thread.
        
        Args:
            cmd: Command name (load_play, pause, resume, seek, set_volume, quit).
            *args: Command arguments.
        """
        self._cmd_queue.put((cmd, args))

    def _pygame_poll(self):
        """Polling thread that tracks playback position and detects track end.
        
        Runs every 250ms to update position and trigger track-end callbacks.
        """
        import pygame
        while self._timer_active:
            try:
                busy = pygame.mixer.music.get_busy()
                pos = pygame.mixer.music.get_pos()
                if busy and pos >= 0:
                    if not self._pending_cmd:
                        self._position_ms = self._seek_base_ms + pos
                    if self.on_position_change:
                        self._call_on_ui(self.on_position_change, self._position_ms)
                # Detect natural track end
                if self._was_busy and not busy and self._is_playing:
                    self._call_on_ui(self._on_track_ended)
                self._was_busy = busy
            except Exception:
                pass
            time.sleep(0.1)

    def _pygame_get_duration(self, path: str) -> int:
        """Get the duration of an audio file using mutagen.
        
        Args:
            path: Path to the audio file.
        
        Returns:
            Duration in milliseconds, or 0 if unavailable.
        """
        import mutagen
        try:
            mf = mutagen.File(path)
            if mf and mf.info:
                return int(mf.info.length * 1000)
        except Exception as ex:
            logger.warning(f"Could not read duration for {path}: {ex}")
        return 0

    # ======================== flet_audio backend (mobile) ========================

    def _init_flet_audio(self):
        """Initialize the flet_audio backend for mobile platforms.
        
        Uses the pre-created Audio instance from page._flet_audio (created
        in main.py) so the build scanner detects the flet_audio plugin.
        Sets up event handlers for load, duration, position, and state changes.
        """
        from flet_audio import AudioState, ReleaseMode

        if hasattr(self.page, '_flet_audio') and self.page._flet_audio is not None:
            self._audio = self.page._flet_audio
        else:
            import flet_audio
            self._audio = flet_audio.Audio(
                autoplay=False,
                volume=self._volume,
                release_mode=ReleaseMode.RELEASE,
            )

        self._audio.on_loaded = self._fa_on_loaded
        self._audio.on_duration_change = self._fa_on_duration
        self._audio.on_position_change = self._fa_on_position
        self._audio.on_state_change = self._fa_on_state
        self._audio.release_mode = ReleaseMode.RELEASE
        self._audio.volume = self._volume
        self.page.update()

        # Position tracking state
        self._seek_base_ms = 0
        self._timer_active = True
        self._position_timer = None
        self._start_fa_timer()

    def _start_fa_timer(self):
        """Start the periodic position timer for flet_audio backend."""
        self._position_timer = threading.Timer(0.1, self._fa_tick)
        self._position_timer.start()

    def _fa_tick(self):
        """Timer callback that updates position for flet_audio backend."""
        if self._is_playing:
            self._position_ms += 100
        if self.on_position_change:
            self._call_on_ui(self.on_position_change, self._position_ms)
        if self._timer_active:
            self._position_timer = threading.Timer(0.1, self._fa_tick)
            self._position_timer.start()

    def _fa_on_loaded(self, e):
        """Handle audio loaded event from flet_audio."""
        self._loading = False
        if self.on_loading_change:
            self._call_on_ui(self.on_loading_change, False)

    def _fa_on_duration(self, e):
        """Handle duration change event from flet_audio."""
        if e.duration is not None:
            self._duration_ms = int(e.duration)

    def _fa_on_position(self, e):
        """Handle position change event from flet_audio."""
        self._position_ms = e.position

    def _fa_on_state(self, e):
        """Handle state change event from flet_audio (detects track completion)."""
        from flet_audio import AudioState
        if e.state == AudioState.COMPLETED:
            self._call_on_ui(self._on_track_ended)

    def _fa_get_duration(self, path: str) -> int:
        """Get duration using mutagen as fallback for flet_audio.
        
        Args:
            path: Path to the audio file.
        
        Returns:
            Duration in milliseconds, or 0 if unavailable.
        """
        try:
            import mutagen
            mf = mutagen.File(path)
            if mf and mf.info:
                return int(mf.info.length * 1000)
        except Exception:
            pass
        return 0

    # ======================== No-op backend (fallback) ========================

    def _init_noop(self):
        """Initialize a no-op audio backend when neither flet_audio nor pygame is available.

        Prevents crashes on platforms where neither audio backend works
        (e.g. iOS without flet_audio support), allowing the UI to display
        and function normally without playback.
        """
        self._use_pygame = False
        self._timer_active = True
        self._noop_timer = threading.Timer(1.0, self._noop_tick)
        self._noop_timer.start()

    def _noop_tick(self):
        """Periodic tick for no-op backend — keeps the timer alive only."""
        if self._timer_active:
            self._noop_timer = threading.Timer(1.0, self._noop_tick)
            self._noop_timer.start()

    # ======================== Cross-backend helpers ========================

    async def capture_ui_loop(self):
        """Capture the UI event loop reference for thread-safe callbacks.
        
        Called once during app initialization to store the running event loop.
        """
        self._ui_loop = asyncio.get_running_loop()

    def _call_on_ui(self, fn, *args):
        """Safely call a function on the UI thread.
        
        Attempts multiple strategies to ensure the callback runs on the
        main UI thread: direct event loop call, stored loop reference,
        or direct invocation as fallback.
        
        Args:
            fn: The callback function to invoke.
            *args: Arguments to pass to the function.
        """
        try:
            loop = asyncio.get_running_loop()
            if loop and loop.is_running():
                loop.call_soon_threadsafe(fn, *args)
                return
        except RuntimeError:
            pass
        if self._ui_loop is not None:
            self._ui_loop.call_soon_threadsafe(fn, *args)
            return
        try:
            fn(*args)
        except Exception as ex:
            logger.error(f"_call_on_ui error: {ex}")

    # ======================== Public API ========================

    def shutdown(self):
        """Shut down the audio player and release resources.
        
        Stops all timers, joins worker threads, and cleans up
        the audio backend (Pygame mixer or flet_audio control).
        """
        self._timer_active = False
        if self._use_pygame:
            self._pygame_send("quit")
            self._worker.join(timeout=2)
            try:
                import pygame
                pygame.mixer.music.stop()
                pygame.mixer.quit()
            except Exception:
                pass
        elif hasattr(self, '_audio') and self._audio is not None:
            if self._position_timer:
                self._position_timer.cancel()
            self._audio = None
        else:
            if self._noop_timer:
                self._noop_timer.cancel()
        logger.debug("Audio player shut down")

    def play_track(self, track: Track):
        """Play a single track, replacing the current queue.
        
        Args:
            track: The Track object to play.
        """
        logger.info(f"play_track: {track.title}")
        self.queue = [track]
        self.current_index = 0
        self._load_current()

    def play_tracks(self, tracks: List[Track], initial_index: int = 0):
        """Play a list of tracks starting from the specified index.
        
        Args:
            tracks: List of Track objects to add to the queue.
            initial_index: Index in the list to start playing from.
        """
        if not tracks:
            return
        logger.info(f"play_tracks: {len(tracks)} tracks, start index={initial_index}")
        self.queue = list(tracks)
        self.current_index = initial_index
        self._load_current()

    def _load_current(self):
        """Load and start playing the track at current_index.
        
        Handles file existence check, metadata loading, and
        initializes the appropriate audio backend. Triggers all
        registered callbacks for track change, play state, and queue updates.
        """
        if self.current_index < 0 or self.current_index >= len(self.queue):
            logger.warning(f"_load_current: invalid index {self.current_index}")
            return
        track = self.queue[self.current_index]
        logger.info(f"_load_current: index={self.current_index} track={track.title}")
        path = track.path
        if not os.path.exists(path):
            logger.error(f"File not found: {path}")
            return

        self._loading = True
        if self.on_loading_change:
            self._call_on_ui(self.on_loading_change, True)

        # Load audio using the appropriate backend
        if self._use_pygame:
            self._duration_ms = self._pygame_get_duration(path)
            logger.debug(f"Duration: {self._duration_ms}ms")
            self._seek_base_ms = 0
            self._position_ms = 0
            self._pending_cmd = True
            self._pygame_send("load_play", path)
        elif hasattr(self, '_audio'):
            self._position_ms = 0
            self._duration_ms = 0
            self._is_playing = False
            self._audio.autoplay = True
            self._audio.src = path
            self.page.update()
        else:
            logger.warning("No audio backend available, skipping playback")

        self._is_playing = True
        self._loading = False

        # Notify UI components of the changes
        if self.on_loading_change:
            self._call_on_ui(self.on_loading_change, False)
        if self.on_play_state_change:
            self._call_on_ui(self.on_play_state_change, True)
        if self.on_track_change:
            self._call_on_ui(self.on_track_change, CurrentTrackData(
                id=track.id, title=track.title, artist=track.artist,
                album=track.album, path=track.path, art_uri=track.art_uri,
                lyrics=track.lyrics, lyrics_offset=track.lyrics_offset,
            ))
        if self.on_queue_change:
            self._call_on_ui(self.on_queue_change)

    def play_current(self):
        """Restart the current track from the beginning."""
        if self.current_index >= 0 and self.current_index < len(self.queue):
            self.seek(0)
            self._is_playing = True
            if self.on_play_state_change:
                self._call_on_ui(self.on_play_state_change, True)

    def toggle_play_pause(self):
        """Toggle between play and pause states.
        
        If no track is loaded but the queue has items, starts playback.
        """
        if self._is_playing:
            if self._use_pygame:
                self._pygame_send("pause")
            elif hasattr(self, '_audio'):
                asyncio.create_task(self._audio.pause())
            self._is_playing = False
            if self.on_play_state_change:
                self._call_on_ui(self.on_play_state_change, False)
        else:
            if self.current_index >= 0 and self.current_index < len(self.queue):
                if self._use_pygame:
                    self._pygame_send("resume")
                elif hasattr(self, '_audio'):
                    asyncio.create_task(self._audio.resume())
                self._is_playing = True
                if self.on_play_state_change:
                    self._call_on_ui(self.on_play_state_change, True)
            elif self.queue:
                self._load_current()

    def next(self):
        """Advance to the next track in the queue.
        
        Respects shuffle and repeat modes:
        - shuffle: Random next track
        - repeat all: Wraps to beginning
        - no repeat: Stops at end of queue
        """
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
                return
        self._load_current()

    def previous(self):
        """Go back to the previous track in the queue.
        
        Clamps to index 0 if already at the beginning.
        """
        if not self.queue:
            return
        self.current_index -= 1
        if self.current_index < 0:
            self.current_index = 0
        self._load_current()

    def seek(self, position_ms: int):
        """Seek to a specific position in the current track.
        
        Args:
            position_ms: Target position in milliseconds.
        """
        if self._use_pygame:
            self._seek_base_ms = position_ms
            self._position_ms = position_ms
            self._pending_cmd = True
            self._pygame_send("seek", position_ms)
            if self.on_position_change:
                self._call_on_ui(self.on_position_change, position_ms)
        elif hasattr(self, '_audio'):
            asyncio.create_task(self._audio.seek(position_ms))
            self._position_ms = position_ms

    def set_volume(self, volume: float):
        self._volume = max(0.0, min(1.0, volume))
        db.set_setting("player_volume", str(round(self._volume, 2)))
        if self._use_pygame:
            self._pygame_send("set_volume", self._volume)
        elif hasattr(self, '_audio'):
            self._audio.volume = self._volume
            self.page.update()

    def get_current_track(self) -> Optional[Track]:
        """Get the currently playing track object.
        
        Returns:
            The current Track object, or None if no track is loaded.
        """
        if 0 <= self.current_index < len(self.queue):
            return self.queue[self.current_index]
        return None

    def _on_track_ended(self):
        """Handle natural track completion.
        
        Implements repeat-one, repeat-all, and sequential playback logic.
        Stops playback if at the end of the queue with no repeat.
        """
        logger.debug("Track ended naturally")
        if self.repeat_mode == "one":
            self.play_current()
        elif self.current_index < len(self.queue) - 1:
            self.next()
        elif self.repeat_mode == "all" and self.queue:
            self.current_index = 0
            self._load_current()
        else:
            self._is_playing = False
            if self.on_play_state_change:
                self._call_on_ui(self.on_play_state_change, False)
            if self.on_loading_change:
                self._call_on_ui(self.on_loading_change, False)

    @property
    def is_playing(self) -> bool:
        """Whether audio is currently playing."""
        return self._is_playing

    @property
    def position_ms(self) -> int:
        """Current playback position in milliseconds."""
        return self._position_ms

    @property
    def duration_ms(self) -> int:
        """Total duration of the current track in milliseconds."""
        return self._duration_ms

    @property
    def volume(self) -> float:
        """Current volume level (0.0 to 1.0)."""
        return self._volume

    @property
    def loading(self) -> bool:
        """Whether a track is currently being loaded."""
        return self._loading
