import 'dart:io';
import 'package:flutter/material.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/data/playlist_repository.dart';
import 'package:groovybox/providers/audio_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AlbumDetailScreen extends HookConsumerWidget {
  final AlbumData album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(playlistRepositoryProvider.notifier);
    final tracksAsync = repo.watchAlbumTracks(album.album);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(album.album),
              background: album.artUri != null
                  ? Image.file(File(album.artUri!), fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.album,
                        size: 100,
                        color: Colors.white54,
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
                  child: Center(child: Text('No tracks in this album')),
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
                                _playAlbum(ref, tracks);
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
      subtitle: Text(_formatDuration(track.duration)),
      onTap: () {
        _playAlbum(ref, tracks, initialIndex: index);
      },
      trailing: const Icon(Icons.play_circle_outline),
    );
  }

  void _playAlbum(WidgetRef ref, List<Track> tracks, {int initialIndex = 0}) {
    final audioHandler = ref.read(audioHandlerProvider);
    audioHandler.playTracks(tracks, initialIndex: initialIndex);
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final d = Duration(milliseconds: durationMs);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
