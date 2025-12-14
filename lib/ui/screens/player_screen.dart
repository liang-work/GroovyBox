import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../../providers/audio_provider.dart';
import '../../logic/metadata_service.dart';

class PlayerScreen extends HookConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<Playlist>(
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

          return Column(
            children: [
              // Cover Art
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: metadataAsync.when(
                      data: (meta) => Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
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
                                child: Icon(
                                  Icons.music_note,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                              )
                            : null,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Track Info
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
                    error: (_, __) =>
                        Text(Uri.parse(media.uri).pathSegments.last),
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

              const SizedBox(height: 32),

              // Lyrics (Placeholder)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No Lyrics Available',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Progress Bar
              StreamBuilder<Duration>(
                stream: player.stream.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;

                  return StreamBuilder<Duration>(
                    stream: player.stream.duration,
                    builder: (context, durationSnapshot) {
                      final totalDuration =
                          durationSnapshot.data ?? Duration.zero;
                      final max = totalDuration.inSeconds.toDouble();
                      final value = position.inSeconds.toDouble().clamp(
                        0.0,
                        max > 0 ? max : 0.0,
                      );

                      return Column(
                        children: [
                          Slider(
                            value: value,
                            min: 0,
                            max: max > 0 ? max : 1.0,
                            onChanged: (val) {
                              player.seek(Duration(seconds: val.toInt()));
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position)),
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

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 32),
                    onPressed: player.previous,
                  ),
                  const SizedBox(width: 16),
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
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 32),
                    onPressed: player.next,
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
