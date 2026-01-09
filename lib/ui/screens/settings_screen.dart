import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:groovybox/data/track_repository.dart';


import 'package:groovybox/providers/settings_provider.dart';
import 'package:groovybox/providers/watch_folder_provider.dart';
import 'package:groovybox/providers/remote_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final watchFoldersAsync = ref.watch(watchFoldersProvider);
    final remoteProvidersAsync = ref.watch(remoteProvidersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settingsTitle'))),
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
                        Text(
                          context.tr('autoScan'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        SwitchListTile(
                          title: Text(context.tr('autoScanMusicLibraries')),
                          subtitle: Text(
                            context.tr('autoScanDescription'),
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
                          title: Text(context.tr('watchForChanges')),
                          subtitle: Text(
                            context.tr('watchForChangesDescription'),
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
                                Text(
                                  context.tr('musicLibraries'),
                                  style: const TextStyle(
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
                                      tooltip: context.tr('scanLibraries'),
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _addMusicLibrary(context, ref),
                                      icon: const Icon(Symbols.add),
                                      tooltip: context.tr('addMusicLibrary'),
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              context.tr('addMusicLibraryDescription'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ).padding(horizontal: 16, top: 16, bottom: 8),
                        watchFoldersAsync.when(
                          data: (folders) => folders.isEmpty
                              ? Text(
                                  context.tr('noMusicLibrariesAdded'),
                                  style: const TextStyle(
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
                                Text(
                                  context.tr('remoteProviders'),
                                  style: const TextStyle(
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
                                      tooltip: context.tr('indexRemoteProviders'),
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _addRemoteProvider(context, ref),
                                      icon: const Icon(Symbols.add),
                                      tooltip: context.tr('addRemoteProvider'),
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              context.tr('remoteProvidersDescription'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ).padding(horizontal: 16, top: 16, bottom: 8),
                        remoteProvidersAsync.when(
                          data: (providers) => providers.isEmpty
                              ? Text(
                                  context.tr('noRemoteProvidersAdded'),
                                  style: const TextStyle(
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
                        Text(
                          context.tr('playerSettings'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        Text(
                          context.tr('playerSettingsDescription'),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: Text(context.tr('defaultPlayerScreen')),
                          subtitle: Text(
                            context.tr('defaultPlayerScreenDescription'),
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
                          title: Text(context.tr('lyricsMode')),
                          subtitle: Text(
                            context.tr('lyricsModeDescription'),
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
                        SwitchListTile(
                          title: Text(context.tr('continuePlaying')),
                          subtitle: Text(
                            context.tr('continuePlayingDescription'),
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          value: settings.continuePlays,
                          onChanged: (value) {
                            ref
                                .read(continuePlaysProvider.notifier)
                                .update(value);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // App Settings Section
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('appSettings'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        Text(
                          context.tr('appSettingsDescription'),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: Text(context.tr('language')),
                          subtitle: Text(
                            context.tr('languageDescription'),
                          ),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<Locale>(
                              value: context.locale,
                              onChanged: (Locale? value) {
                                if (value != null) {
                                  EasyLocalization.of(context)!.setLocale(value);
                                } else {
                                  EasyLocalization.of(context)!.resetLocale();
                                }
                              },
                              items: [
                                DropdownMenuItem(
                                  value: const Locale('en'),
                                  child: Text(context.tr('english')),
                                ),
                                DropdownMenuItem(
                                  value: const Locale('zh'),
                                  child: Text(context.tr('chinese')),
                                ),
                              ],
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
                        Text(
                          context.tr('databaseManagement'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        Text(
                          context.tr('databaseManagementDescription'),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: Text(context.tr('resetTrackDatabase')),
                          subtitle: Text(
                            context.tr('resetTrackDatabaseDescription'),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _resetTrackDatabase(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(context.tr('reset')),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Gap for mini player
                  const Gap(80),
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
              SnackBar(content: Text(context.tr('addedMusicLibrary', args: [path]))),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('errorAddingLibrary', args: [e.toString()]))));
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
          SnackBar(content: Text(context.tr('librariesScannedSuccessfully'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('errorScanningLibraries', args: [e.toString()]))));
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
                SnackBar(
                  content: Text(context.tr('noActiveRemoteProviders')),
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
                  context.tr('indexedRemoteProviders', args: [activeProviders.length.toString()]),
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
        title: Text(context.tr('addRemoteProviderDialog')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverUrlController,
              decoration: InputDecoration(
                labelText: context.tr('serverUrl'),
                hintText: context.tr('serverUrlHint'),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: context.tr('username')),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: context.tr('password')),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final serverUrl = serverUrlController.text.trim();
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();

              if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('allFieldsRequired'))),
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
                      content: Text(context.tr('addedRemoteProvider', args: [serverUrl])),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('errorAddingProvider', args: [e.toString()]))),
                  );
                }
              }
            },
            child: Text(context.tr('add')),
          ),
        ],
      ),
    );
  }

  void _resetTrackDatabase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('resetTrackDatabase')),
        content: Text(
          context.tr('confirmResetTrackDatabase'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog

              try {
                final repository = ref.read(trackRepositoryProvider.notifier);
                await repository.clearAllTracks();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('trackDatabaseReset')),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('errorResettingDatabase', args: [e.toString()]))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('reset')),
          ),
        ],
      ),
    );
  }
}
