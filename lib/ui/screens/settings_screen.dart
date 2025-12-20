import 'package:flutter/material.dart';
import 'package:groovybox/data/track_repository.dart';
import 'package:groovybox/providers/settings_provider.dart';
import 'package:groovybox/providers/watch_folder_provider.dart';
import 'package:groovybox/providers/remote_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final watchFoldersAsync = ref.watch(watchFoldersProvider);
    final remoteProvidersAsync = ref.watch(remoteProvidersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto Scan Section
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto Scan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        SwitchListTile(
                          title: const Text('Auto-scan music libraries'),
                          subtitle: const Text(
                            'Automatically scan music libraries for new music files',
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          value: settings.watchForChanges,
                          onChanged: (value) {
                            ref
                                .read(watchForChangesProvider.notifier)
                                .update(value);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Watch Folders Section
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
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
                                      onPressed: () =>
                                          _scanLibraries(context, ref),
                                      icon: const Icon(Symbols.refresh),
                                      tooltip: 'Scan Libraries',
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _addMusicLibrary(context, ref),
                                      icon: const Icon(Symbols.add),
                                      tooltip: 'Add Music Library',
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Text(
                              'Add folder libraries to index music files. Files will be copied to internal storage for playback.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ).padding(horizontal: 16, top: 16, bottom: 8),
                        watchFoldersAsync.when(
                          data: (folders) => folders.isEmpty
                              ? const Text(
                                  'No music libraries added yet.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ).padding(horizontal: 16, vertical: 8)
                              : Column(
                                  children: folders
                                      .map(
                                        (folder) => ListTile(
                                          title: Text(folder.name),
                                          subtitle: Text(folder.path),
                                          contentPadding: const EdgeInsets.only(
                                            left: 16,
                                            right: 16,
                                          ),
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
                                                icon: const Icon(
                                                  Symbols.delete,
                                                ),
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Remote Providers Section
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Remote Providers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _indexRemoteProviders(context, ref),
                                      icon: const Icon(Symbols.refresh),
                                      tooltip: 'Index Remote Providers',
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _addRemoteProvider(context, ref),
                                      icon: const Icon(Symbols.add),
                                      tooltip: 'Add Remote Provider',
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Text(
                              'Connect to remote media servers like Jellyfin to access your music library.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ).padding(horizontal: 16, top: 16, bottom: 8),
                        remoteProvidersAsync.when(
                          data: (providers) => providers.isEmpty
                              ? const Text(
                                  'No remote providers added yet.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ).padding(horizontal: 16, vertical: 8)
                              : Column(
                                  children: providers
                                      .map(
                                        (provider) => ListTile(
                                          title: Text(provider.name),
                                          subtitle: Text(provider.serverUrl),
                                          contentPadding: const EdgeInsets.only(
                                            left: 16,
                                            right: 16,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Switch(
                                                value: provider.isActive,
                                                onChanged: (value) {
                                                  ref
                                                      .read(
                                                        remoteProviderServiceProvider,
                                                      )
                                                      .toggleRemoteProvider(
                                                        provider.id,
                                                        value,
                                                      );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Symbols.delete,
                                                ),
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        remoteProviderServiceProvider,
                                                      )
                                                      .removeRemoteProvider(
                                                        provider.id,
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
                              Text('Error loading providers: $error'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Player Settings Section
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Player Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        const Text(
                          'Configure player behavior and display options.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: const Text('Default Player Screen'),
                          subtitle: const Text(
                            'Choose which screen to show when opening the player.',
                          ),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<DefaultPlayerScreen>(
                              value: settings.defaultPlayerScreen,
                              onChanged: (DefaultPlayerScreen? value) {
                                if (value != null) {
                                  ref
                                      .read(
                                        defaultPlayerScreenProvider.notifier,
                                      )
                                      .update(value);
                                }
                              },
                              items: DefaultPlayerScreen.values.map((screen) {
                                return DropdownMenuItem(
                                  value: screen,
                                  child: Text(screen.displayName),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Lyrics Mode'),
                          subtitle: const Text(
                            'Choose how lyrics are displayed.',
                          ),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<LyricsMode>(
                              value: settings.lyricsMode,
                              onChanged: (LyricsMode? value) {
                                if (value != null) {
                                  ref
                                      .read(lyricsModeProvider.notifier)
                                      .update(value);
                                }
                              },
                              items: LyricsMode.values.map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode.displayName),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Database Management Section
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Database Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        const Text(
                          'Manage your music database and cached files.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: const Text('Reset Track Database'),
                          subtitle: const Text(
                            'Remove all tracks from database and delete cached files. This action cannot be undone.',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _resetTrackDatabase(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  void _indexRemoteProviders(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(remoteProviderServiceProvider);
      final providersAsync = ref.read(remoteProvidersProvider);

      providersAsync.when(
        data: (providers) async {
          final activeProviders = providers.where((p) => p.isActive).toList();

          if (activeProviders.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No active remote providers to index'),
                ),
              );
            }
            return;
          }

          for (final provider in activeProviders) {
            try {
              await service.indexRemoteProvider(provider.id);
            } catch (e) {
              debugPrint('Error indexing provider ${provider.name}: $e');
            }
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Indexed ${activeProviders.length} remote provider(s)',
                ),
              ),
            );
          }
        },
        loading: () {
          // Providers are still loading, do nothing
        },
        error: (error, _) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading providers: $error')),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error indexing remote providers: $e')),
        );
      }
    }
  }

  void _addRemoteProvider(BuildContext context, WidgetRef ref) {
    final serverUrlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Remote Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://your-jellyfin-server.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final serverUrl = serverUrlController.text.trim();
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();

              if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required')),
                );
                return;
              }

              try {
                final service = ref.read(remoteProviderServiceProvider);
                await service.addRemoteProvider(serverUrl, username, password);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added remote provider: $serverUrl'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding provider: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _resetTrackDatabase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Track Database'),
        content: const Text(
          'This will permanently delete all tracks from the database and remove all cached music files and album art. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog

              try {
                final repository = ref.read(trackRepositoryProvider.notifier);
                await repository.clearAllTracks();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Track database has been reset'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error resetting database: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
