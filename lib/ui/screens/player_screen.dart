import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:groovybox/data/db.dart' as db;
import 'package:groovybox/logic/lyrics_parser.dart';
import 'package:groovybox/logic/metadata_service.dart';
import 'package:groovybox/providers/audio_provider.dart';
import 'package:groovybox/providers/db_provider.dart';
import 'package:groovybox/providers/lrc_fetcher_provider.dart';
import 'package:groovybox/ui/widgets/mini_player.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:media_kit/media_kit.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class PlayerScreen extends HookConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;

    final tabController = useTabController(initialLength: 2);
    final isMobile = MediaQuery.sizeOf(context).width <= 640;

    return StreamBuilder<Playlist>(
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

        return Scaffold(
          body: Stack(
            children: [
              // Main content (StreamBuilder)
              Builder(
                builder: (context) {
                  if (isMobile) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 64,
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
              ),
              // IconButton
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  iconSize: 24,
                ),
              ),
              // TabBar (if mobile)
              if (isMobile)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 54,
                  right: 54,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                ),
              _LyricsRefreshButton(trackPath: path),
            ],
          ),
        );
      },
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
    return Stack(
      children: [
        // Left Side: Cover + Controls
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
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
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
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
              Expanded(child: const SizedBox.shrink()),
            ],
          ),
        ),
        // Overlaid Lyrics on the right
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.sizeOf(context).width * 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
        ? ref.watch(trackByPathProvider(trackPath!))
        : const AsyncValue<db.Track?>.data(null);

    final metadataAsync = trackPath != null
        ? ref.watch(trackMetadataProvider(trackPath!))
        : const AsyncValue<TrackMetadata?>.data(null);

    final lyricsFetcher = ref.watch(lyricsFetcherProvider);
    final musixmatchProviderInstance = ref.watch(musixmatchProvider);
    final neteaseProviderInstance = ref.watch(neteaseProvider);

    return trackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (track) {
        if (track == null || track.lyrics == null) {
          // Show fetch lyrics UI
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No Lyrics Available',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Fetch Lyrics'),
                onPressed: track != null && trackPath != null
                    ? () => _showFetchLyricsDialog(
                        context,
                        ref,
                        track,
                        trackPath!,
                        metadataAsync.value,
                        musixmatchProviderInstance,
                        neteaseProviderInstance,
                      )
                    : null,
              ),
              if (lyricsFetcher.isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(),
                ),
              if (lyricsFetcher.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    lyricsFetcher.error!,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (lyricsFetcher.successMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    lyricsFetcher.successMessage!,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        }

        try {
          final lyricsData = LyricsData.fromJsonString(track.lyrics!);

          if (lyricsData.type == 'timed') {
            return _TimedLyricsView(
              lyrics: lyricsData,
              player: player,
              trackPath: trackPath!,
            );
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

  void _showFetchLyricsDialog(
    BuildContext context,
    WidgetRef ref,
    db.Track track,
    String trackPath,
    dynamic metadataObj,
    musixmatchProvider,
    neteaseProvider,
  ) {
    final metadata = metadataObj as TrackMetadata?;
    final searchTerm =
        '${metadata?.title ?? track.title} ${metadata?.artist ?? track.artist}'
            .trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fetch Lyrics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Search term: $searchTerm'),
            const SizedBox(height: 16),
            Text('Choose a provider:'),
            const SizedBox(height: 8),
            Row(
              children: [
                _ProviderButton(
                  name: 'Musixmatch',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(lyricsFetcherProvider.notifier)
                        .fetchLyricsForTrack(
                          trackId: track.id,
                          searchTerm: searchTerm,
                          provider: musixmatchProvider,
                          trackPath: trackPath,
                        );
                  },
                ),
                const SizedBox(width: 8),
                _ProviderButton(
                  name: 'NetEase',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(lyricsFetcherProvider.notifier)
                        .fetchLyricsForTrack(
                          trackId: track.id,
                          searchTerm: searchTerm,
                          provider: neteaseProvider,
                          trackPath: trackPath,
                        );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;

  const _ProviderButton({required this.name, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(onPressed: onPressed, child: Text(name)),
    );
  }
}

class _LyricsRefreshButton extends HookConsumerWidget {
  final String trackPath;

  const _LyricsRefreshButton({required this.trackPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackAsync = ref.watch(trackByPathProvider(trackPath));
    final metadataAsync = ref.watch(trackMetadataProvider(trackPath));
    final musixmatchProviderInstance = ref.watch(musixmatchProvider);
    final neteaseProviderInstance = ref.watch(neteaseProvider);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: IconButton(
        icon: const Icon(Icons.refresh),
        iconSize: 24,
        tooltip: 'Refresh Lyrics',
        onPressed: () => _showLyricsRefreshDialog(
          context,
          ref,
          trackAsync,
          metadataAsync,
          musixmatchProviderInstance,
          neteaseProviderInstance,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showFetchLyricsDialog(
    BuildContext context,
    WidgetRef ref,
    db.Track track,
    String trackPath,
    dynamic metadataObj,
    musixmatchProvider,
    neteaseProvider,
  ) {
    final metadata = metadataObj as TrackMetadata?;
    final searchTerm =
        '${metadata?.title ?? track.title} ${metadata?.artist ?? track.artist}'
            .trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fetch Lyrics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Search term: $searchTerm'),
            const SizedBox(height: 16),
            Text('Choose a provider:'),
            const SizedBox(height: 8),
            Row(
              children: [
                _ProviderButton(
                  name: 'Musixmatch',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(lyricsFetcherProvider.notifier)
                        .fetchLyricsForTrack(
                          trackId: track.id,
                          searchTerm: searchTerm,
                          provider: musixmatchProvider,
                          trackPath: trackPath,
                        );
                  },
                ),
                const SizedBox(width: 8),
                _ProviderButton(
                  name: 'NetEase',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(lyricsFetcherProvider.notifier)
                        .fetchLyricsForTrack(
                          trackId: track.id,
                          searchTerm: searchTerm,
                          provider: neteaseProvider,
                          trackPath: trackPath,
                        );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLyricsRefreshDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<db.Track?> trackAsync,
    AsyncValue<TrackMetadata> metadataAsync,
    musixmatchProvider,
    neteaseProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lyrics Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose an action:'),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-fetch'),
                        onPressed: trackAsync.maybeWhen(
                          data: (track) => track != null
                              ? () {
                                  Navigator.of(context).pop();
                                  final metadata = metadataAsync.value;
                                  _showFetchLyricsDialog(
                                    context,
                                    ref,
                                    track,
                                    trackPath,
                                    metadata,
                                    musixmatchProvider,
                                    neteaseProvider,
                                  );
                                }
                              : null,
                          orElse: () => null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: trackAsync.maybeWhen(
                          data: (track) => track != null
                              ? () async {
                                  Navigator.of(context).pop();
                                  debugPrint(
                                    'Clearing lyrics for track ${track.id}',
                                  );
                                  final database = ref.read(databaseProvider);
                                  await (database.update(
                                    database.tracks,
                                  )..where((t) => t.id.equals(track.id))).write(
                                    db.TracksCompanion(
                                      lyrics: const drift.Value.absent(),
                                    ),
                                  );
                                  debugPrint('Cleared lyrics from database');
                                  // Invalidate the track provider to refresh the UI
                                  ref.invalidate(
                                    trackByPathProvider(trackPath),
                                  );
                                  debugPrint(
                                    'Invalidated track provider for $trackPath',
                                  );
                                }
                              : null,
                          orElse: () => null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Adjust Timing'),
                    onPressed: trackAsync.maybeWhen(
                      data: (track) => track != null
                          ? () {
                              Navigator.of(context).pop();
                              _showLyricsOffsetDialog(
                                context,
                                ref,
                                track,
                                trackPath,
                              );
                            }
                          : null,
                      orElse: () => null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLyricsOffsetDialog(
    BuildContext context,
    WidgetRef ref,
    db.Track track,
    String trackPath,
  ) {
    final offsetController = TextEditingController(
      text: track.lyricsOffset.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Lyrics Timing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter offset in milliseconds.\nPositive values delay lyrics, negative values advance them.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: offsetController,
              decoration: const InputDecoration(
                labelText: 'Offset (ms)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final offset = int.tryParse(offsetController.text) ?? 0;
              Navigator.of(context).pop();

              final database = ref.read(databaseProvider);
              await (database.update(database.tracks)
                    ..where((t) => t.id.equals(track.id)))
                  .write(db.TracksCompanion(lyricsOffset: drift.Value(offset)));

              // Invalidate the track provider to refresh the UI
              ref.invalidate(trackByPathProvider(trackPath));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TimedLyricsView extends HookConsumerWidget {
  final LyricsData lyrics;
  final Player player;
  final String trackPath;

  const _TimedLyricsView({
    required this.lyrics,
    required this.player,
    required this.trackPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width > 640;

    final listController = useMemoized(() => ListController(), []);
    final scrollController = useScrollController();
    final wheelScrollController = useMemoized(
      () => FixedExtentScrollController(),
      [],
    );
    final previousIndex = useState(-1);

    // Get track data to access lyrics offset
    final trackAsync = ref.watch(trackByPathProvider(trackPath));

    return trackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (track) {
        final lyricsOffset = track?.lyricsOffset ?? 0;

        return StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final positionMs = position.inMilliseconds + lyricsOffset;

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
                if (isDesktop) {
                  if (wheelScrollController.hasClients) {
                    wheelScrollController.animateToItem(
                      currentIndex,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  listController.animateToItem(
                    index: currentIndex,
                    scrollController: scrollController,
                    alignment: 0.5,
                    duration: (_) => const Duration(milliseconds: 300),
                    curve: (_) => Curves.easeOutCubic,
                  );
                }
              });
            }

            if (isDesktop) {
              return ListWheelScrollView.useDelegate(
                controller: wheelScrollController,
                itemExtent: 50,
                perspective: 0.002,
                offAxisFraction: 1.5,
                squeeze: 1.0,
                diameterRatio: 2,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: lyrics.lines.length,
                  builder: (context, index) {
                    final line = lyrics.lines[index];
                    final isActive = index == currentIndex;

                    return Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (line.timeMs != null) {
                              player.seek(Duration(milliseconds: line.timeMs!));
                            }
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(
                                    fontSize: isActive ? 18 : 16,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                  ),
                              textAlign: TextAlign.left,
                              child: Text(
                                line.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
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
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      child: Text(line.text),
                    ),
                  ),
                );
              },
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
              error: (_, _) => Text(Uri.parse(media.uri).pathSegments.last),
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
                            formatDuration(
                              Duration(milliseconds: currentValue.toInt()),
                            ),
                          ),
                          Text(formatDuration(totalDuration)),
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
                initialData: player.state.shuffle,
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
              initialData: player.state.playing,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return IconButton.filled(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      key: ValueKey<bool>(playing),
                      size: 48,
                    ),
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
                initialData: player.state.playlistMode,
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

  String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Provider to fetch a single track by path
final trackByPathProvider = FutureProvider.family<db.Track?, String>((
  ref,
  trackPath,
) async {
  final database = ref.watch(databaseProvider);
  return (database.select(
    database.tracks,
  )..where((t) => t.path.equals(trackPath))).getSingleOrNull();
});
