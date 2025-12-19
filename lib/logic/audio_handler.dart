import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:groovybox/data/db.dart' as db;
import 'package:groovybox/logic/metadata_service.dart';
import 'package:groovybox/providers/audio_provider.dart';
import 'package:groovybox/providers/theme_provider.dart';
import 'package:groovybox/providers/remote_provider.dart';
import 'package:groovybox/providers/db_provider.dart';

class AudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final media_kit.Player _player;
  List<MediaItem> _queue = [];
  int _queueIndex = 0;
  ProviderContainer? _container;

  AudioHandler() : _player = media_kit.Player() {
    // Configure for audio
    // _player.setPlaylistMode(PlaylistMode.loop); // Optional

    // Listen to player state changes and broadcast to audio_service
    _player.stream.playing.listen((playing) {
      _broadcastPlaybackState();
    });

    _player.stream.position.listen((position) {
      _broadcastPlaybackState();
    });

    _player.stream.duration.listen((duration) {
      _broadcastPlaybackState();
    });

    _player.stream.playlist.listen((playlist) {
      if (playlist.medias.isNotEmpty) {
        final currentIndex = playlist.index;
        if (currentIndex >= 0 && currentIndex < _queue.length) {
          _queueIndex = currentIndex;
          final currentItem = _queue[_queueIndex];
          mediaItem.add(currentItem);
          _updateThemeFromCurrentTrack(currentItem);
        }
      }
    });
  }

  // Method to set the provider container for theme updates
  void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  // Update theme color based on current track's album art and set current metadata and track
  void _updateThemeFromCurrentTrack(MediaItem mediaItem) async {
    if (_container == null) return;

    try {
      TrackMetadata? metadata;
      db.Track? track;

      // For remote tracks, get metadata from database
      final urlResolver = _container!.read(remoteUrlResolverProvider);
      if (urlResolver.isProtocolUrl(mediaItem.id)) {
        final database = _container!.read(databaseProvider);
        track = await (database.select(
          database.tracks,
        )..where((t) => t.path.equals(mediaItem.id))).getSingleOrNull();

        if (track != null) {
          // Fetch album art bytes for remote tracks
          Uint8List? artBytes;
          if (track.artUri != null) {
            try {
              final response = await http.get(Uri.parse(track.artUri!));
              if (response.statusCode == 200) {
                artBytes = response.bodyBytes;
              }
            } catch (e) {
              // Ignore art fetching errors
            }
          }

          metadata = TrackMetadata(
            title: track.title,
            artist: track.artist,
            album: track.album,
            artBytes: artBytes,
          );

          // Update theme from album art
          final seedColorNotifier = _container!.read(
            seedColorProvider.notifier,
          );
          seedColorNotifier.updateFromAlbumArtBytes(artBytes);
        }
      } else {
        // For local tracks, get from database and use metadata service
        final database = _container!.read(databaseProvider);
        track = await (database.select(
          database.tracks,
        )..where((t) => t.path.equals(mediaItem.id))).getSingleOrNull();

        // Use metadata service for local tracks
        final metadataService = MetadataService();
        metadata = await metadataService.getMetadata(mediaItem.id);

        // Update theme from album art
        final seedColorNotifier = _container!.read(seedColorProvider.notifier);
        seedColorNotifier.updateFromAlbumArtBytes(metadata.artBytes);
      }

      // Set current track
      final trackNotifier = _container!.read(currentTrackProvider.notifier);
      if (track != null) {
        trackNotifier.setTrack(CurrentTrackData.fromTrack(track));
      } else {
        trackNotifier.clear();
      }

      // Set current track metadata
      final metadataNotifier = _container!.read(
        currentTrackMetadataProvider.notifier,
      );
      if (metadata != null) {
        metadataNotifier.setMetadata(metadata);
      } else {
        metadataNotifier.clear();
      }
    } catch (e) {
      // If metadata retrieval fails, reset to default color and clear metadata/track
      final seedColorNotifier = _container!.read(seedColorProvider.notifier);
      seedColorNotifier.resetToDefault();

      final trackNotifier = _container!.read(currentTrackProvider.notifier);
      trackNotifier.clear();

      final metadataNotifier = _container!.read(
        currentTrackMetadataProvider.notifier,
      );
      metadataNotifier.clear();
    }
  }

  media_kit.Player get player => _player;

  // AudioService callbacks
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
      await _player.jump(_queueIndex);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queueIndex > 0) {
      _queueIndex--;
      await _player.jump(_queueIndex);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queueIndex = index;
      await _player.jump(index);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _queue.add(mediaItem);
    queue.add(_queue);
    await _updatePlaylist();
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    if (index >= 0 && index <= _queue.length) {
      _queue.insert(index, mediaItem);
      queue.add(_queue);
      await _updatePlaylist();
    }
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    _queue.remove(mediaItem);
    queue.add(_queue);
    await _updatePlaylist();
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    _queue = List.from(queue);
    this.queue.add(_queue);
    await _updatePlaylist();
  }

  Future<void> _updatePlaylist() async {
    if (_container == null) {
      // Fallback if container not set
      final medias = _queue.map((item) => media_kit.Media(item.id)).toList();
      if (medias.isNotEmpty) {
        await _player.open(media_kit.Playlist(medias, index: _queueIndex));
      }
      return;
    }

    final urlResolver = _container!.read(remoteUrlResolverProvider);
    final medias = <media_kit.Media>[];

    for (final item in _queue) {
      String uri = item.id;

      // Check if this is a protocol URL that needs resolution
      if (urlResolver.isProtocolUrl(item.id)) {
        final resolvedUrl = await urlResolver.resolveUrl(item.id);
        if (resolvedUrl != null) {
          uri = resolvedUrl;
        } else {
          // If resolution fails, skip this track or use original URL
          continue;
        }
      }

      // Store the original track path in extras for queue lookup
      medias.add(media_kit.Media(uri, extras: {'trackPath': item.id}));
    }

    if (medias.isNotEmpty) {
      await _player.open(media_kit.Playlist(medias, index: _queueIndex));
    }
  }

  void _broadcastPlaybackState() {
    final playing = _player.state.playing;
    final position = _player.state.position;
    final duration = _player.state.duration;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: duration,
        speed: 1.0,
        queueIndex: _queueIndex,
      ),
    );
  }

  // New methods that accept Track objects with proper metadata
  Future<void> playTrack(db.Track track) async {
    final mediaItem = _trackToMediaItem(track);
    await updateQueue([mediaItem]);
  }

  Future<void> playTracks(List<db.Track> tracks, {int initialIndex = 0}) async {
    final mediaItems = tracks.map(_trackToMediaItem).toList();
    _queueIndex = initialIndex;
    await updateQueue(mediaItems);
  }

  MediaItem _trackToMediaItem(db.Track track) {
    return MediaItem(
      id: track.path,
      album: track.album,
      title: track.title,
      artist: track.artist,
      duration: track.duration != null
          ? Duration(milliseconds: track.duration!)
          : null,
      artUri: track.artUri != null ? Uri.file(track.artUri!) : null,
    );
  }

  // Legacy methods for backward compatibility
  Future<void> setSource(String path) async {
    final mediaItem = MediaItem(
      id: path,
      album: 'Unknown Album',
      title: _extractTitleFromPath(path),
      artist: 'Unknown Artist',
    );
    await updateQueue([mediaItem]);
  }

  Future<void> openPlaylist(
    List<media_kit.Media> medias, {
    int initialIndex = 0,
  }) async {
    final mediaItems = medias.map((media) {
      return MediaItem(
        id: media.uri,
        album: 'Unknown Album',
        title: _extractTitleFromPath(media.uri),
        artist: 'Unknown Artist',
      );
    }).toList();

    _queueIndex = initialIndex;
    await updateQueue(mediaItems);
  }

  String _extractTitleFromPath(String path) {
    return path.split('/').last.split('.').first;
  }

  void dispose() {
    _player.dispose();
  }
}
