import 'package:flutter/material.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/data/playlist_repository.dart';
import 'package:groovybox/l10n/app_localizations.dart';
import 'package:groovybox/ui/screens/playlist_detail_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:styled_widget/styled_widget.dart';

class PlaylistsTab extends HookConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(playlistRepositoryProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.add),
            trailing: const Icon(Symbols.chevron_right).padding(right: 8),
            title: Text(AppLocalizations.of(context)!.createOne),
            subtitle: Text(AppLocalizations.of(context)!.addNewPlaylist),
            onTap: () async {
              final nameController = TextEditingController();
              final name = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.newPlaylist),
                  content: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.playlistName,
                    ),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, nameController.text),
                      child: Text(AppLocalizations.of(context)!.create),
                    ),
                  ],
                ),
              );
              if (name != null && name.isNotEmpty) {
                await repo.createPlaylist(name);
              }
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Playlist>>(
              stream: repo.watchAllPlaylists(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final playlists = snapshot.data!;

                if (playlists.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noPlaylistsYet));
                }

                return ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(Symbols.queue_music),
                      title: Text(playlist.name),
                      subtitle: Text(
                        '${playlist.createdAt.day}/${playlist.createdAt.month}/${playlist.createdAt.year}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Symbols.delete),
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
          ),
        ],
      ),
    );
  }
}
