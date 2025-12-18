import 'package:flutter/material.dart';
import 'package:groovybox/providers/settings_provider.dart';
import 'package:groovybox/providers/watch_folder_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final watchFoldersAsync = ref.watch(watchFoldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto Scan Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auto Scan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Auto-scan music libraries'),
                        subtitle: const Text(
                          'Automatically scan music libraries for new music files',
                        ),
                        value: settings.autoScan,
                        onChanged: (value) {
                          ref.read(autoScanProvider.notifier).update(value);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Watch for changes'),
                        subtitle: const Text(
                          'Monitor music libraries for file changes',
                        ),
                        value: settings.watchForChanges,
                        onChanged: (value) {
                          ref
                              .read(watchForChangesProvider.notifier)
                              .update(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Watch Folders Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Music Libraries',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _scanLibraries(context, ref),
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Scan Libraries',
                              ),
                              IconButton(
                                onPressed: () => _addMusicLibrary(context, ref),
                                icon: const Icon(Icons.add),
                                tooltip: 'Add Music Library',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add folder libraries to index music files. Files will be copied to internal storage for playback.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      watchFoldersAsync.when(
                        data: (folders) => folders.isEmpty
                            ? const Text(
                                'No music libraries added yet.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              )
                            : Column(
                                children: folders
                                    .map(
                                      (folder) => ListTile(
                                        title: Text(folder.name),
                                        subtitle: Text(folder.path),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch(
                                              value: folder.isActive,
                                              onChanged: (value) {
                                                ref
                                                    .read(
                                                      watchFolderServiceProvider,
                                                    )
                                                    .toggleWatchFolder(
                                                      folder.id,
                                                      value,
                                                    );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      watchFolderServiceProvider,
                                                    )
                                                    .removeWatchFolder(
                                                      folder.id,
                                                    );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                        loading: () => const CircularProgressIndicator(),
                        error: (error, _) =>
                            Text('Error loading libraries: $error'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading settings: $error')),
      ),
    );
  }

  void _addMusicLibrary(BuildContext context, WidgetRef ref) {
    FilePicker.platform.getDirectoryPath().then((path) async {
      if (path != null) {
        try {
          final service = ref.read(watchFolderServiceProvider);
          await service.addWatchFolder(path, recursive: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added music library: $path')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error adding library: $e')));
          }
        }
      }
    });
  }

  void _scanLibraries(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(watchFolderServiceProvider);
      await service.scanWatchFolders();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Libraries scanned successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scanning libraries: $e')));
      }
    }
  }
}
