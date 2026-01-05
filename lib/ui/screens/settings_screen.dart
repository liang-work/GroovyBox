import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:groovybox/data/track_repository.dart';
import 'package:groovybox/l10n/app_localizations.dart';
import 'package:groovybox/providers/locale_provider.dart';
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
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
                          AppLocalizations.of(context)!.autoScan,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        SwitchListTile(
                          title: Text(AppLocalizations.of(context)!.autoScanMusicLibraries),
                          subtitle: Text(
                            AppLocalizations.of(context)!.autoScanDescription,
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
                          title: Text(AppLocalizations.of(context)!.watchForChanges),
                          subtitle: Text(
                            AppLocalizations.of(context)!.watchForChangesDescription,
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
                                  AppLocalizations.of(context)!.musicLibraries,
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
                                      tooltip: AppLocalizations.of(context)!.scanLibraries,
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _addMusicLibrary(context, ref),
                                      icon: const Icon(Symbols.add),
                                      tooltip: AppLocalizations.of(context)!.addMusicLibrary,
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
                              AppLocalizations.of(context)!.addMusicLibraryDescription,
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
                                  AppLocalizations.of(context)!.noMusicLibrariesAdded,
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
                                  AppLocalizations.of(context)!.remoteProviders,
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
                                      tooltip: AppLocalizations.of(context)!.indexRemoteProviders,
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _addRemoteProvider(context, ref),
                                      icon: const Icon(Symbols.add),
                                      tooltip: AppLocalizations.of(context)!.addRemoteProvider,
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
                              AppLocalizations.of(context)!.remoteProvidersDescription,
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
                                  AppLocalizations.of(context)!.noRemoteProvidersAdded,
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
                          AppLocalizations.of(context)!.playerSettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        Text(
                          AppLocalizations.of(context)!.playerSettingsDescription,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.defaultPlayerScreen),
                          subtitle: Text(
                            AppLocalizations.of(context)!.defaultPlayerScreenDescription,
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
                          title: Text(AppLocalizations.of(context)!.lyricsMode),
                          subtitle: Text(
                            AppLocalizations.of(context)!.lyricsModeDescription,
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
                          title: Text(AppLocalizations.of(context)!.continuePlaying),
                          subtitle: Text(
                            AppLocalizations.of(context)!.continuePlayingDescription,
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
                          AppLocalizations.of(context)!.appSettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        Text(
                          AppLocalizations.of(context)!.appSettingsDescription,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.language),
                          subtitle: Text(
                            AppLocalizations.of(context)!.languageDescription,
                          ),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<Locale>(
                              value: ref.watch(localeProvider),
                              onChanged: (Locale? value) {
                                if (value != null) {
                                  ref.read(localeProvider.notifier).setLocale(value);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: Locale('en'),
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: Locale('zh'),
                                  child: Text('中文'),
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
                          AppLocalizations.of(context)!.databaseManagement,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).padding(horizontal: 16, top: 16),
                        Text(
                          AppLocalizations.of(context)!.databaseManagementDescription,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ).padding(horizontal: 16, bottom: 8),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.resetTrackDatabase),
                          subtitle: Text(
                            AppLocalizations.of(context)!.resetTrackDatabaseDescription,
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _resetTrackDatabase(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(AppLocalizations.of(context)!.reset),
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
              SnackBar(content: Text(AppLocalizations.of(context)!.addedMusicLibrary(path))),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingLibrary(e.toString()))));
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
          SnackBar(content: Text(AppLocalizations.of(context)!.librariesScannedSuccessfully)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorScanningLibraries(e.toString()))));
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
                  content: Text(AppLocalizations.of(context)!.noActiveRemoteProviders),
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
                  AppLocalizations.of(context)!.indexedRemoteProviders(activeProviders.length),
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
        title: Text(AppLocalizations.of(context)!.addRemoteProviderDialog),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverUrlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.serverUrl,
                hintText: AppLocalizations.of(context)!.serverUrlHint,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.username),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.password),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final serverUrl = serverUrlController.text.trim();
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();

              if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.allFieldsRequired)),
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
                      content: Text(AppLocalizations.of(context)!.addedRemoteProvider(serverUrl)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingProvider(e.toString()))),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  void _resetTrackDatabase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetTrackDatabase),
        content: Text(
          AppLocalizations.of(context)!.confirmResetTrackDatabase,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
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
                      content: Text(AppLocalizations.of(context)!.trackDatabaseReset),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.errorResettingDatabase(e.toString()))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.reset),
          ),
        ],
      ),
    );
  }
}
