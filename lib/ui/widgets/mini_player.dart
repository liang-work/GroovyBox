import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:media_kit/media_kit.dart';
import '../../providers/audio_provider.dart';
import '../../logic/metadata_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends HookConsumerWidget {
  final bool enableTapToOpen;

  const MiniPlayer({super.key, this.enableTapToOpen = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;

    final isDragging = useState(false);
    final dragValue = useState(0.0);

    return StreamBuilder<Playlist>(
      stream: player.stream.playlist,
      initialData: player.state.playlist,
      builder: (context, snapshot) {
        final index = snapshot.data?.index ?? 0;
        final medias = snapshot.data?.medias ?? [];
        if (medias.isEmpty || index < 0 || index >= medias.length) {
          return const SizedBox.shrink();
        }
        final media = medias[index];
        final path = Uri.parse(media.uri).path;
        // Using common parse for path if it's a file URI
        final filePath = Uri.decodeFull(path);

        final metadataAsync = ref.watch(trackMetadataProvider(filePath));

        Widget content = Container(
          height: 72,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Bar
              SizedBox(
                height: 4,
                width: double.infinity,
                child: StreamBuilder<Duration>(
                  stream: player.stream.position,
                  initialData: player.state.position,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: player.stream.duration,
                      initialData: player.state.duration,
                      builder: (context, durationSnapshot) {
                        final total = durationSnapshot.data ?? Duration.zero;
                        final max = total.inMilliseconds.toDouble();
                        final positionValue = position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, max > 0 ? max : 0.0);

                        final currentValue = isDragging.value
                            ? dragValue.value
                            : positionValue;

                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            // Let's keep a small thumb or make it visible on hover/touch.
                            // Standard Slider has a thumb.
                            trackHeight: 2,
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            trackShape: const RectangularSliderTrackShape(),
                          ),
                          child: Slider(
                            padding: EdgeInsets.zero,
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
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Cover Art (Small)
                    AspectRatio(
                      aspectRatio: 1,
                      child: metadataAsync.when(
                        data: (meta) => meta.artBytes != null
                            ? Image.memory(meta.artBytes!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                ),
                              ),
                        loading: () => Container(color: Colors.grey[800]),
                        error: (_, _) => Container(color: Colors.grey[800]),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            metadataAsync.when(
                              data: (meta) => Text(
                                meta.title ??
                                    Uri.parse(media.uri).pathSegments.last,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const Text('Loading...'),
                              error: (_, _) =>
                                  Text(Uri.parse(media.uri).pathSegments.last),
                            ),
                            metadataAsync.when(
                              data: (meta) => Text(
                                meta.artist ?? 'Unknown Artist',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    StreamBuilder<bool>(
                      stream: player.stream.playing,
                      initialData: player.state.playing,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IconButton.filled(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
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
                              ),
                            ),
                            onPressed: playing ? player.pause : player.play,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (enableTapToOpen) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const PlayerScreen(),
                ),
              );
            },
            child: content,
          );
        } else {
          return content;
        }
      },
    );
  }
}
