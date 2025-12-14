import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../providers/audio_provider.dart';
import '../../logic/metadata_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends HookConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;

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

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const PlayerScreen(),
              ),
            );
          },
          child: Container(
            height: 64,
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
                    error: (_, __) => Container(color: Colors.grey[800]),
                  ),
                ),
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
                          error: (_, __) =>
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
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<bool>(
                  stream: player.stream.playing,
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: playing ? player.pause : player.play,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
