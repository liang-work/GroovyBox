import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:media_kit/media_kit.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../../providers/audio_provider.dart';
import '../../providers/db_provider.dart';
import '../../logic/metadata_service.dart';
import '../../logic/lyrics_parser.dart';
import '../../data/db.dart' as db;
import '../widgets/mini_player.dart';

class PlayerScreen extends HookConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;

    final tabController = useTabController(initialLength: 2);
    final isMobile = MediaQuery.sizeOf(context).width <= 640;

    return Scaffold(
      body: Stack(
        children: [
          // Main content (StreamBuilder)
          StreamBuilder<Playlist>(
            stream: player.stream.playlist,
            initialData: player.state.playlist,
            builder: (context, snapshot) {
              final index = snapshot.data?.index ?? 0;
              final medias = snapshot.data?.medias ?? [];
              if (medias.isEmpty || index < 0 || index >= medias.length) {
                return const Center(child: Text('No media selected'));
              }
              final media = medias[index];
              final path = Uri.decodeFull(Uri.parse(media.uri).path);

              final metadataAsync = ref.watch(trackMetadataProvider(path));

              return Builder(
                builder: (context) {
                  if (isMobile) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 48,
                      ),
                      child: _MobileLayout(
                        player: player,
                        tabController: tabController,
                        metadataAsync: metadataAsync,
                        media: media,
                        trackPath: path,
                      ),
                    );
                  } else {
                    return _DesktopLayout(
                      player: player,
                      metadataAsync: metadataAsync,
                      media: media,
                      trackPath: path,
                    );
                  }
                },
              );
            },
          ),
          // IconButton
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          // TabBar (if mobile)
          if (isMobile)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 50,
              right: 50,
              child: TabBar(
                controller: tabController,
                tabAlignment: TabAlignment.fill,
                tabs: const [
                  Tab(text: 'Cover'),
                  Tab(text: 'Lyrics'),
                ],
                dividerHeight: 0,
                indicatorColor: Colors.transparent,
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Player player;
  final TabController tabController;
  final AsyncValue<TrackMetadata> metadataAsync;
  final Media media;
  final String trackPath;

  const _MobileLayout({
    required this.player,
    required this.tabController,
    required this.metadataAsync,
    required this.media,
    required this.trackPath,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: _PlayerCoverArt(metadataAsync: metadataAsync),
                  ),
                ),
              ),
              _PlayerControls(
                player: player,
                metadataAsync: metadataAsync,
                media: media,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Lyrics Tab with Mini Player
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: _PlayerLyrics(trackPath: trackPath, player: player),
              ),
            ),
            MiniPlayer(enableTapToOpen: false),
          ],
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Player player;
  final AsyncValue<TrackMetadata> metadataAsync;
  final Media media;
  final String trackPath;

  const _DesktopLayout({
    required this.player,
    required this.metadataAsync,
    required this.media,
    required this.trackPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Cover + Controls
        Expanded(
          flex: 1,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _PlayerCoverArt(
                              metadataAsync: metadataAsync,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _PlayerControls(
                    player: player,
                    metadataAsync: metadataAsync,
                    media: media,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        // Right Side: Lyrics
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: _PlayerLyrics(trackPath: trackPath, player: player),
          ),
        ),
      ],
    );
  }
}

class _PlayerCoverArt extends StatelessWidget {
  final AsyncValue<TrackMetadata> metadataAsync;

  const _PlayerCoverArt({required this.metadataAsync});

  @override
  Widget build(BuildContext context) {
    return metadataAsync.when(
      data: (meta) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          image: meta.artBytes != null
              ? DecorationImage(
                  image: MemoryImage(meta.artBytes!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: meta.artBytes == null
            ? const Center(
                child: Icon(Icons.music_note, size: 80, color: Colors.white54),
              )
            : null,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(Icons.error_outline, size: 80, color: Colors.white54),
        ),
      ),
    );
  }
}

class _PlayerLyrics extends HookConsumerWidget {
  final String? trackPath;
  final Player player;

  const _PlayerLyrics({this.trackPath, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for track data (including lyrics) by path
    final trackAsync = trackPath != null
        ? ref.watch(_trackByPathProvider(trackPath!))
        : const AsyncValue<db.Track?>.data(null);

    return trackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (track) {
        if (track == null || track.lyrics == null) {
          return const Center(
            child: Text(
              'No Lyrics Available',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        }

        try {
          final lyricsData = LyricsData.fromJsonString(track.lyrics!);

          if (lyricsData.type == 'timed') {
            return _TimedLyricsView(lyrics: lyricsData, player: player);
          } else {
            // Plain text lyrics
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lyricsData.lines.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    lyricsData.lines[index].text,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          }
        } catch (e) {
          return Center(child: Text('Error parsing lyrics: $e'));
        }
      },
    );
  }
}

// Provider to fetch a single track by path
final _trackByPathProvider = FutureProvider.family<db.Track?, String>((
  ref,
  trackPath,
) async {
  final database = ref.watch(databaseProvider);
  return (database.select(
    database.tracks,
  )..where((t) => t.path.equals(trackPath))).getSingleOrNull();
});

class _TimedLyricsView extends HookWidget {
  final LyricsData lyrics;
  final Player player;

  const _TimedLyricsView({required this.lyrics, required this.player});

  @override
  Widget build(BuildContext context) {
    final listController = useMemoized(() => ListController(), []);
    final scrollController = useScrollController();
    final previousIndex = useState(-1);

    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final positionMs = position.inMilliseconds;

        // Find current line index
        int currentIndex = 0;
        for (int i = 0; i < lyrics.lines.length; i++) {
          if ((lyrics.lines[i].timeMs ?? 0) <= positionMs) {
            currentIndex = i;
          } else {
            break;
          }
        }

        // Auto-scroll when current line changes
        if (currentIndex != previousIndex.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            previousIndex.value = currentIndex;
            listController.animateToItem(
              index: currentIndex,
              scrollController: scrollController,
              alignment: 0.5,
              duration: (_) => const Duration(milliseconds: 300),
              curve: (_) => Curves.easeOutCubic,
            );
          });
        }

        return SuperListView.builder(
          padding: EdgeInsets.only(
            top: 0.25 * MediaQuery.sizeOf(context).height,
            bottom: 0.25 * MediaQuery.sizeOf(context).height,
          ),
          listController: listController,
          controller: scrollController,
          itemCount: lyrics.lines.length,
          itemBuilder: (context, index) {
            final line = lyrics.lines[index];
            final isActive = index == currentIndex;

            return InkWell(
              onTap: () {
                if (line.timeMs != null) {
                  player.seek(Duration(milliseconds: line.timeMs!));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: isActive ? 20 : 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  child: Text(line.text, textAlign: TextAlign.center),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlayerControls extends HookWidget {
  final Player player;
  final AsyncValue<TrackMetadata> metadataAsync;
  final Media media;

  const _PlayerControls({
    required this.player,
    required this.metadataAsync,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    final isDragging = useState(false);
    final dragValue = useState(0.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title & Artist
        Column(
          children: [
            metadataAsync.when(
              data: (meta) => Text(
                meta.title ?? Uri.parse(media.uri).pathSegments.last,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox(height: 32),
              error: (_, __) => Text(Uri.parse(media.uri).pathSegments.last),
            ),
            const SizedBox(height: 8),
            metadataAsync.when(
              data: (meta) => Text(
                meta.artist ?? 'Unknown Artist',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              loading: () => const SizedBox(height: 24),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Progress Bar
        StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: player.stream.duration,
              initialData: player.state.duration,
              builder: (context, durationSnapshot) {
                final totalDuration = durationSnapshot.data ?? Duration.zero;
                final max = totalDuration.inMilliseconds.toDouble();
                final positionValue = position.inMilliseconds.toDouble().clamp(
                  0.0,
                  max > 0 ? max : 0.0,
                );

                final currentValue = isDragging.value
                    ? dragValue.value
                    : positionValue;

                return Column(
                  children: [
                    Slider(
                      value: currentValue,
                      min: 0,
                      max: max > 0 ? max : 1.0,
                      onChanged: (val) {
                        isDragging.value = true;
                        dragValue.value = val;
                      },
                      onChangeEnd: (val) {
                        isDragging.value = false;
                        player.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(
                              Duration(milliseconds: currentValue.toInt()),
                            ),
                          ),
                          Text(_formatDuration(totalDuration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // Media Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              icon: StreamBuilder<bool>(
                stream: player.stream.shuffle,
                builder: (context, snapshot) {
                  final shuffle = snapshot.data ?? false;
                  return Icon(
                    Icons.shuffle,
                    color: shuffle
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  );
                },
              ),
              onPressed: () {
                player.setShuffle(!player.state.shuffle);
              },
            ),
            const SizedBox(width: 16),
            // Previous
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 32),
              onPressed: player.previous,
            ),
            const SizedBox(width: 16),
            // Play/Pause
            StreamBuilder<bool>(
              stream: player.stream.playing,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return IconButton.filled(
                  icon: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    size: 48,
                  ),
                  onPressed: playing ? player.pause : player.play,
                  iconSize: 48,
                );
              },
            ),
            const SizedBox(width: 16),
            // Next
            IconButton(
              icon: const Icon(Icons.skip_next, size: 32),
              onPressed: player.next,
            ),
            const SizedBox(width: 16),
            // Loop Mode
            IconButton(
              icon: StreamBuilder<PlaylistMode>(
                stream: player.stream.playlistMode,
                builder: (context, snapshot) {
                  final mode = snapshot.data ?? PlaylistMode.none;
                  IconData icon;
                  Color? color;
                  switch (mode) {
                    case PlaylistMode.none:
                      icon = Icons.repeat;
                      color = Theme.of(context).disabledColor;
                      break;
                    case PlaylistMode.single:
                      icon = Icons.repeat_one;
                      color = Theme.of(context).colorScheme.primary;
                      break;
                    case PlaylistMode.loop:
                      icon = Icons.repeat;
                      color = Theme.of(context).colorScheme.primary;
                      break;
                  }
                  return Icon(icon, color: color);
                },
              ),
              onPressed: () {
                final mode = player.state.playlistMode;
                switch (mode) {
                  case PlaylistMode.none:
                    player.setPlaylistMode(PlaylistMode.single);
                    break;
                  case PlaylistMode.single:
                    player.setPlaylistMode(PlaylistMode.loop);
                    break;
                  case PlaylistMode.loop:
                    player.setPlaylistMode(PlaylistMode.none);
                    break;
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Volume Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: StreamBuilder<double>(
            stream: player.stream.volume,
            builder: (context, snapshot) {
              final volume = snapshot.data ?? 100.0;
              return Row(
                children: [
                  Icon(
                    volume == 0
                        ? Icons.volume_off
                        : volume < 50
                        ? Icons.volume_down
                        : Icons.volume_up,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: volume.round().toString(),
                      onChanged: (value) {
                        player.setVolume(value);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
