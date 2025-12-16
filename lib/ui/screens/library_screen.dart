import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/data/playlist_repository.dart';
import 'package:groovybox/data/track_repository.dart';
import 'package:groovybox/logic/lyrics_parser.dart';
import 'package:groovybox/providers/audio_provider.dart';
import 'package:groovybox/ui/tabs/albums_tab.dart';
import 'package:groovybox/ui/tabs/playlists_tab.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

class LibraryScreen extends HookConsumerWidget {
  const LibraryScreen({super.key});

  static const List<String> audioExtensions = [
    'mp3',
    'm4a',
    'wav',
    'flac',
    'aac',
    'ogg',
    'wma',
    'm4p',
    'aiff',
    'au',
    'dss',
  ];

  static const List<String> lyricsExtensions = ['lrc', 'srt', 'txt'];

  static const List<String> allAllowedExtensions = [
    ...audioExtensions,
    ...lyricsExtensions,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can define a stream provider locally or in repository file.
    // For now, using StreamBuilder is easiest since `watchAllTracks` returns a Stream.
    // Or better: `ref.watch(trackListStreamProvider)`.

    // Let's assume we use StreamBuilder for now to avoid creating another file/provider on the fly.
    final repo = ref.watch(trackRepositoryProvider.notifier);
    final selectedTrackIds = useState<Set<int>>({});
    final isSelectionMode = selectedTrackIds.value.isNotEmpty;

    void toggleSelection(int id) {
      final newSet = Set<int>.from(selectedTrackIds.value);
      if (newSet.contains(id)) {
        newSet.remove(id);
      } else {
        newSet.add(id);
      }
      selectedTrackIds.value = newSet;
    }

    void clearSelection() {
      selectedTrackIds.value = {};
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: clearSelection,
                ),
                title: Text('${selectedTrackIds.value.length} selected'),
                backgroundColor: Theme.of(context).primaryColorDark,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.playlist_add),
                    tooltip: 'Add to Playlist',
                    onPressed: () {
                      _batchAddToPlaylist(
                        context,
                        ref,
                        selectedTrackIds.value.toList(),
                        clearSelection,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () {
                      _batchDelete(
                        context,
                        ref,
                        selectedTrackIds.value.toList(),
                        clearSelection,
                      );
                    },
                  ),
                  const Gap(8),
                ],
              )
            : AppBar(
                centerTitle: true,
                title: const Text('Library'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Tracks', icon: Icon(Icons.audiotrack)),
                    Tab(text: 'Albums', icon: Icon(Icons.album)),
                    Tab(text: 'Playlists', icon: Icon(Icons.queue_music)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Import Files',
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: allAllowedExtensions,
                        allowMultiple: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final paths = result.files
                            .map((f) => f.path)
                            .whereType<String>()
                            .toList();
                        if (paths.isNotEmpty) {
                          // Separate audio and lyrics files
                          final audioPaths = paths.where((path) {
                            final ext = p
                                .extension(path)
                                .toLowerCase()
                                .replaceFirst('.', '');
                            return audioExtensions.contains(ext);
                          }).toList();
                          final lyricsPaths = paths.where((path) {
                            final ext = p
                                .extension(path)
                                .toLowerCase()
                                .replaceFirst('.', '');
                            return lyricsExtensions.contains(ext);
                          }).toList();

                          // Import tracks if any
                          if (audioPaths.isNotEmpty) {
                            await repo.importFiles(audioPaths);
                          }

                          // Import lyrics if any
                          if (lyricsPaths.isNotEmpty) {
                            await _batchImportLyricsFromPaths(
                              context,
                              ref,
                              lyricsPaths,
                            );
                          }
                        }
                      }
                    },
                  ),
                  const Gap(8),
                ],
              ),
        body: TabBarView(
          children: [
            // Tracks Tab (Existing Logic)
            StreamBuilder<List<Track>>(
              stream: repo.watchAllTracks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tracks = snapshot.data!;
                if (tracks.isEmpty) {
                  return const Center(child: Text('No tracks yet. Add some!'));
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: 72 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isSelected = selectedTrackIds.value.contains(
                      track.id,
                    );

                    if (isSelectionMode) {
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.white10,
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (_) => toggleSelection(track.id),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${track.artist ?? 'Unknown Artist'} • ${_formatDuration(track.duration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => toggleSelection(track.id),
                      );
                    }

                    return Dismissible(
                      key: Key('track_${track.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete Track?'),
                              content: Text(
                                'Are you sure you want to delete "${track.title}"? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        ref
                            .read(trackRepositoryProvider.notifier)
                            .deleteTrack(track.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted "${track.title}"')),
                        );
                      },
                      child: ListTile(
                        leading: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              image: track.artUri != null
                                  ? DecorationImage(
                                      image: FileImage(File(track.artUri!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: track.artUri == null
                                ? const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${track.artist ?? 'Unknown Artist'} • ${_formatDuration(track.duration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelectionMode
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  _showTrackOptions(context, ref, track);
                                },
                              ),
                        onTap: () {
                          final audio = ref.read(audioHandlerProvider);
                          audio.setSource(track.path);
                          audio.play();
                        },
                        onLongPress: () {
                          // Enter selection mode
                          toggleSelection(track.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),

            // Albums Tab
            const AlbumsTab(),

            // Playlists Tab
            const PlaylistsTab(),
          ],
        ),
      ),
    );
  }

  void _showTrackOptions(BuildContext context, WidgetRef ref, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, ref, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Metadata'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lyrics_outlined),
                title: const Text('Import Lyrics'),
                onTap: () {
                  Navigator.pop(context);
                  _importLyricsForTrack(context, ref, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Track',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(trackRepositoryProvider.notifier)
                      .deleteTrack(track.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Track track,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        // Fetch playlists
        // Note: Using a hook/provider inside dialog builder might need a Consumer or similar if stream updates.
        // For simplicity, we'll assume the user wants to pick from *current* playlists.
        // Or we can use a Consumer widget inside the dialog.
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final playlistsAsync = ref
                    .watch(playlistRepositoryProvider.notifier)
                    .watchAllPlaylists();
                return StreamBuilder<List<Playlist>>(
                  stream: playlistsAsync,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final playlists = snapshot.data!;
                    if (playlists.isEmpty) {
                      return const Text(
                        'No playlists available. Create one first!',
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          title: Text(playlist.name),
                          onTap: () {
                            ref
                                .read(playlistRepositoryProvider.notifier)
                                .addToPlaylist(playlist.id, track.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${playlist.name}'),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Track track) {
    final titleController = TextEditingController(text: track.title);
    final artistController = TextEditingController(text: track.artist);
    final albumController = TextEditingController(text: track.album);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Track'),
        content: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
            ),
            TextField(
              controller: albumController,
              decoration: const InputDecoration(labelText: 'Album'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(trackRepositoryProvider.notifier)
                  .updateMetadata(
                    trackId: track.id,
                    title: titleController.text,
                    artist: artistController.text,
                    album: albumController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final d = Duration(milliseconds: durationMs);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _batchAddToPlaylist(
    BuildContext context,
    WidgetRef ref,
    List<int> trackIds,
    VoidCallback onSuccess,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final playlistsAsync = ref
                    .watch(playlistRepositoryProvider.notifier)
                    .watchAllPlaylists();
                return StreamBuilder<List<Playlist>>(
                  stream: playlistsAsync,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final playlists = snapshot.data!;
                    if (playlists.isEmpty) {
                      return const Text('No playlists available.');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          title: Text(playlist.name),
                          onTap: () async {
                            final repo = ref.read(
                              playlistRepositoryProvider.notifier,
                            );
                            for (final id in trackIds) {
                              await repo.addToPlaylist(playlist.id, id);
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            onSuccess();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${trackIds.length} tracks to ${playlist.name}',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _batchDelete(
    BuildContext context,
    WidgetRef ref,
    List<int> trackIds,
    VoidCallback onSuccess,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tracks?'),
        content: Text(
          'Are you sure you want to delete ${trackIds.length} tracks? '
          'This will remove them from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(trackRepositoryProvider.notifier);
      for (final id in trackIds) {
        await repo.deleteTrack(id);
      }
      onSuccess();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${trackIds.length} tracks')),
      );
    }
  }

  Future<void> _importLyricsForTrack(
    BuildContext context,
    WidgetRef ref,
    Track track,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc', 'srt', 'txt'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final filename = result.files.first.name;

      final lyricsData = LyricsParser.parse(content, filename);
      final lyricsJson = lyricsData.toJsonString();

      await ref
          .read(trackRepositoryProvider.notifier)
          .updateLyrics(track.id, lyricsJson);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${lyricsData.lines.length} lyrics lines for "${track.title}"',
          ),
        ),
      );
    }
  }

  Future<void> _batchImportLyricsFromPaths(
    BuildContext context,
    WidgetRef ref,
    List<String> lyricsPaths,
  ) async {
    if (lyricsPaths.isEmpty) return;

    final repo = ref.read(trackRepositoryProvider.notifier);
    final tracks = await repo.getAllTracks();

    int matched = 0;
    int notMatched = 0;

    for (final path in lyricsPaths) {
      final file = File(path);
      final content = await file.readAsString();
      final filename = p.basename(path);

      // Get basename without extension for matching
      final baseName = filename
          .replaceAll(RegExp(r'\.(lrc|srt|txt)$', caseSensitive: false), '')
          .toLowerCase();

      // Try to find a matching track by title
      final matchingTrack = tracks.where((t) {
        final trackTitle = t.title.toLowerCase();
        return trackTitle == baseName ||
            trackTitle.contains(baseName) ||
            baseName.contains(trackTitle);
      }).firstOrNull;

      if (matchingTrack != null) {
        final lyricsData = LyricsParser.parse(content, filename);
        await repo.updateLyrics(matchingTrack.id, lyricsData.toJsonString());
        matched++;
      } else {
        notMatched++;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Batch import complete: $matched matched, $notMatched not matched',
        ),
      ),
    );
  }
}
