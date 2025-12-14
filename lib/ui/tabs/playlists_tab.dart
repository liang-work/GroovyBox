import 'package:flutter/material.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/data/playlist_repository.dart';
import 'package:groovybox/ui/screens/playlist_detail_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PlaylistsTab extends HookConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(playlistRepositoryProvider.notifier);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameController = TextEditingController();
          final name = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('New Playlist'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Playlist Name'),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, nameController.text),
                  child: const Text('Create'),
                ),
              ],
            ),
          );
          if (name != null && name.isNotEmpty) {
            await repo.createPlaylist(name);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Playlist>>(
        stream: repo.watchAllPlaylists(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final playlists = snapshot.data!;

          if (playlists.isEmpty) {
            return const Center(child: Text('No playlists yet'));
          }

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(playlist.name),
                subtitle: Text(
                  '${playlist.createdAt.day}/${playlist.createdAt.month}/${playlist.createdAt.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => repo.deletePlaylist(playlist.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlaylistDetailScreen(playlist: playlist),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
