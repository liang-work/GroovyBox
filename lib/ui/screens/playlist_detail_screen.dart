import 'package:flutter/material.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/data/playlist_repository.dart';
import 'package:groovybox/providers/audio_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track, Playlist;

class PlaylistDetailScreen extends HookConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(playlistRepositoryProvider.notifier);
    final tracksAsync = repo.watchPlaylistTracks(playlist.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(playlist.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.8),
                      Colors.blue.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.queue_music,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<List<Track>>(
            stream: tracksAsync,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tracks = snapshot.data!;
              if (tracks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No tracks in this playlist')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                _playPlaylist(ref, tracks);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play All'),
                            ),
                          ),
                        ),
                        _buildTrackTile(ref, tracks, index),
                      ],
                    );
                  }
                  return _buildTrackTile(ref, tracks, index);
                }, childCount: tracks.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(WidgetRef ref, List<Track> tracks, int index) {
    final track = tracks[index];
    return ListTile(
      leading: Text(
        '${index + 1}',
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
      title: Text(track.title),
      subtitle: Text(track.artist ?? 'Unknown Artist'),
      trailing: Text(_formatDuration(track.duration)),
      onTap: () {
        _playPlaylist(ref, tracks, initialIndex: index);
      },
    );
  }

  void _playPlaylist(
    WidgetRef ref,
    List<Track> tracks, {
    int initialIndex = 0,
  }) {
    final audioHandler = ref.read(audioHandlerProvider);
    final medias = tracks.map((t) => Media(t.path)).toList();
    audioHandler.openPlaylist(medias, initialIndex: initialIndex);
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final d = Duration(milliseconds: durationMs);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
