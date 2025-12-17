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
    final searchQuery = useState<String>('');
    final isSelectionMode = selectedTrackIds.value.isNotEmpty;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final selectedTab = isLargeScreen ? useState<int>(0) : null;

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

    if (isLargeScreen) {
      return Scaffold(
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
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedTab!.value,
              onDestinationSelected: (index) => selectedTab.value = index,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.audiotrack),
                  label: Text('Tracks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.album),
                  label: Text('Albums'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.queue_music),
                  label: Text('Playlists'),
                ),
              ],
            ),
            Expanded(
              child: _buildTabContent(
                selectedTab.value,
                ref,
                repo,
                selectedTrackIds,
                searchQuery,
                toggleSelection,
                isSelectionMode,
              ),
            ),
          ],
        ),
      );
    } else {
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
              _buildTracksTab(
                ref,
                repo,
                selectedTrackIds,
                searchQuery,
                toggleSelection,
                isSelectionMode,
              ),
              const AlbumsTab(),
              const PlaylistsTab(),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTracksTab(
    WidgetRef ref,
    dynamic repo,
    ValueNotifier<Set<int>> selectedTrackIds,
    ValueNotifier<String> searchQuery,
    void Function(int) toggleSelection,
    bool isSelectionMode,
  ) {
    return StreamBuilder<List<Track>>(
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

        List<Track> filteredTracks;
        if (searchQuery.value.isEmpty) {
          filteredTracks = tracks;
        } else {
          final query = searchQuery.value.toLowerCase();
          filteredTracks = tracks.where((track) {
            if (track.title.toLowerCase().contains(query)) return true;
            if (track.artist?.toLowerCase().contains(query) ?? false)
              return true;
            if (track.album?.toLowerCase().contains(query) ?? false)
              return true;
            if (track.lyrics != null) {
              try {
                final lyricsData = LyricsData.fromJsonString(track.lyrics!);
                for (final line in lyricsData.lines) {
                  if (line.text.toLowerCase().contains(query)) return true;
                }
              } catch (e) {
                // Ignore parsing errors
              }
            }
            return false;
          }).toList();
        }

        if (filteredTracks.isEmpty && searchQuery.value.isNotEmpty) {
          return const Center(child: Text('No tracks match your search.'));
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: 16.0,
              ),
              child: TextField(
                onChanged: (value) => searchQuery.value = value,
                decoration: const InputDecoration(
                  hintText: 'Search tracks...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: 72 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: filteredTracks.length,
                itemBuilder: (context, index) {
                  final track = filteredTracks[index];
                  final isSelected = selectedTrackIds.value.contains(track.id);

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
                        audio.playTrack(track);
                      },
                      onLongPress: () {
                        // Enter selection mode
                        toggleSelection(track.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(
    int index,
    WidgetRef ref,
    dynamic repo,
    ValueNotifier<Set<int>> selectedTrackIds,
    ValueNotifier<String> searchQuery,
    void Function(int) toggleSelection,
    bool isSelectionMode,
  ) {
    switch (index) {
      case 0:
        return _buildTracksTab(
          ref,
          repo,
          selectedTrackIds,
          searchQuery,
          toggleSelection,
          isSelectionMode,
        );
      case 1:
        return const AlbumsTab();
      case 2:
        return const PlaylistsTab();
      default:
        return const SizedBox();
    }
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
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (context) {
        // Fetch playlists
        // Note: Using a hook/provider inside dialog builder might need a Consumer or similar if stream updates.
        // For simplicity, we'll assume the user wants to pick from *current* playlists.
        // Or we can use a Consumer widget inside the dialog.
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.8,
              maxHeight: screenSize.height * 0.6,
            ),
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
    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Track'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenSize.width * 0.8),
          child: Column(
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
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.8,
              maxHeight: screenSize.height * 0.6,
            ),
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
