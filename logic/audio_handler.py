import threading
import queue
import asyncio
import os
import time
import random
from typing import Optional, Callable, List
import flet as ft
from data.models import Track, CurrentTrackData
from logic.logger import logger


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

        self._use_pygame = self._is_desktop()
        if self._use_pygame:
            self._init_pygame()
        else:
            try:
                self._init_flet_audio()
            except Exception as ex:
                logger.warning(f"flet_audio init failed ({ex}), falling back to pygame")
                self._use_pygame = True
                self._init_pygame()

    # --- Platform detection ---

    def _is_desktop(self):
        try:
            p = self.page.platform
            return p in (ft.PagePlatform.WINDOWS, ft.PagePlatform.LINUX, ft.PagePlatform.MACOS)
        except Exception:
            return True

    # ======================== Pygame backend ========================

    def _init_pygame(self):
        import pygame
        pygame.mixer.init(frequency=44100, size=-16, channels=2)
        logger.debug("Pygame mixer initialized")

        self._cmd_queue: queue.Queue = queue.Queue()
        self._worker = threading.Thread(target=self._pygame_worker, daemon=True)
        self._worker.start()
        logger.debug("Audio worker thread started")

        self._seek_base_ms = 0
        self._was_busy = False
        self._timer_active = True
        self._poll_thread = threading.Thread(target=self._pygame_poll, daemon=True)
        self._poll_thread.start()

    def _pygame_worker(self):
        import pygame
        while True:
            cmd, args = self._cmd_queue.get()
            if cmd == "quit":
                break
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
            self._cmd_queue.task_done()

    def _pygame_send(self, cmd, *args):
        self._cmd_queue.put((cmd, args))

    def _pygame_poll(self):
        import pygame
        while self._timer_active:
            try:
                busy = pygame.mixer.music.get_busy()
                pos = pygame.mixer.music.get_pos()
                if busy and pos >= 0:
                    self._position_ms = self._seek_base_ms + pos
                    if self.on_position_change:
                        self._call_on_ui(self.on_position_change, self._position_ms)
                if self._was_busy and not busy and self._is_playing:
                    self._call_on_ui(self._on_track_ended)
                self._was_busy = busy
            except Exception:
                pass
            time.sleep(0.25)

    def _pygame_get_duration(self, path: str) -> int:
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
        import flet_audio
        from flet_audio import AudioState, ReleaseMode

        self._audio = flet_audio.Audio(
            autoplay=False,
            volume=self._volume,
            release_mode=ReleaseMode.RELEASE,
            on_loaded=self._fa_on_loaded,
            on_duration_change=self._fa_on_duration,
            on_position_change=self._fa_on_position,
            on_state_change=self._fa_on_state,
        )
        self.page.overlay.append(self._audio)
        self.page.update()

        self._seek_base_ms = 0
        self._timer_active = True
        self._position_timer = None
        self._start_fa_timer()

    def _start_fa_timer(self):
        self._position_timer = threading.Timer(0.25, self._fa_tick)
        self._position_timer.start()

    def _fa_tick(self):
        if self._is_playing:
            self._position_ms += 250
        if self.on_position_change:
            self._call_on_ui(self.on_position_change, self._position_ms)
        if self._timer_active:
            self._position_timer = threading.Timer(0.25, self._fa_tick)
            self._position_timer.start()

    def _fa_on_loaded(self, e):
        self._loading = False
        if self.on_loading_change:
            self._call_on_ui(self.on_loading_change, False)

    def _fa_on_duration(self, e):
        if e.duration is not None:
            self._duration_ms = int(e.duration)

    def _fa_on_position(self, e):
        self._position_ms = e.position

    def _fa_on_state(self, e):
        from flet_audio import AudioState
        if e.state == AudioState.COMPLETED:
            self._call_on_ui(self._on_track_ended)

    def _fa_get_duration(self, path: str) -> int:
        try:
            import mutagen
            mf = mutagen.File(path)
            if mf and mf.info:
                return int(mf.info.length * 1000)
        except Exception:
            pass
        return 0

    # ======================== Cross-backend helpers ========================

    def _call_on_ui(self, fn, *args):
        try:
            loop = asyncio.get_running_loop()
            if loop and loop.is_running():
                loop.call_soon_threadsafe(fn, *args)
                return
        except RuntimeError:
            pass
        try:
            fn(*args)
        except Exception as ex:
            logger.error(f"_call_on_ui error: {ex}")

    # ======================== Public API ========================

    def shutdown(self):
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
        else:
            if self._position_timer:
                self._position_timer.cancel()
            try:
                self.page.overlay.remove(self._audio)
                self.page.update()
            except Exception:
                pass
        logger.debug("Audio player shut down")

    def play_track(self, track: Track):
        logger.info(f"play_track: {track.title}")
        self.queue = [track]
        self.current_index = 0
        self._load_current()

    def play_tracks(self, tracks: List[Track], initial_index: int = 0):
        if not tracks:
            return
        logger.info(f"play_tracks: {len(tracks)} tracks, start index={initial_index}")
        self.queue = list(tracks)
        self.current_index = initial_index
        self._load_current()

    def _load_current(self):
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

        if self._use_pygame:
            self._duration_ms = self._pygame_get_duration(path)
            logger.debug(f"Duration: {self._duration_ms}ms")
            self._seek_base_ms = 0
            self._pygame_send("load_play", path)
            self._position_ms = 0
        else:
            self._position_ms = 0
            self._duration_ms = 0
            self._is_playing = False
            self._audio.autoplay = True
            self._audio.src = path
            self.page.update()

        self._is_playing = True
        self._loading = False

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
        if self.current_index >= 0 and self.current_index < len(self.queue):
            self.seek(0)
            self._is_playing = True
            if self.on_play_state_change:
                self._call_on_ui(self.on_play_state_change, True)

    def toggle_play_pause(self):
        if self._is_playing:
            if self._use_pygame:
                self._pygame_send("pause")
            else:
                asyncio.create_task(self._audio.pause())
            self._is_playing = False
            if self.on_play_state_change:
                self._call_on_ui(self.on_play_state_change, False)
        else:
            if self.current_index >= 0 and self.current_index < len(self.queue):
                if self._use_pygame:
                    self._pygame_send("resume")
                else:
                    asyncio.create_task(self._audio.resume())
                self._is_playing = True
                if self.on_play_state_change:
                    self._call_on_ui(self.on_play_state_change, True)
            elif self.queue:
                self._load_current()

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
                return
        self._load_current()

    def previous(self):
        if not self.queue:
            return
        self.current_index -= 1
        if self.current_index < 0:
            self.current_index = 0
        self._load_current()

    def seek(self, position_ms: int):
        if self._use_pygame:
            self._seek_base_ms = position_ms
            self._pygame_send("seek", position_ms)
        else:
            asyncio.create_task(self._audio.seek(position_ms))
        self._position_ms = position_ms

    def set_volume(self, volume: float):
        self._volume = max(0.0, min(1.0, volume))
        if self._use_pygame:
            self._pygame_send("set_volume", self._volume)
        else:
            self._audio.volume = self._volume
            self.page.update()

    def get_current_track(self) -> Optional[Track]:
        if 0 <= self.current_index < len(self.queue):
            return self.queue[self.current_index]
        return None

    def _on_track_ended(self):
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
