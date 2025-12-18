import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

enum ImportMode {
  copy('Copy to internal storage'),
  inplace('In-place indexing'),
  mixed('Mixed (both copy and in-place)');

  const ImportMode(this.displayName);
  final String displayName;
}

class SettingsState {
  final ImportMode importMode;
  final bool autoScan;
  final bool watchForChanges;
  final Set<String> supportedFormats;

  const SettingsState({
    this.importMode = ImportMode.mixed,
    this.autoScan = true,
    this.watchForChanges = true,
    this.supportedFormats = const {
      '.mp3',
      '.flac',
      '.wav',
      '.m4a',
      '.aac',
      '.ogg',
      '.wma',
      '.opus',
    },
  });

  SettingsState copyWith({
    ImportMode? importMode,
    bool? autoScan,
    bool? watchForChanges,
    Set<String>? supportedFormats,
  }) {
    return SettingsState(
      importMode: importMode ?? this.importMode,
      autoScan: autoScan ?? this.autoScan,
      watchForChanges: watchForChanges ?? this.watchForChanges,
      supportedFormats: supportedFormats ?? this.supportedFormats,
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const String _importModeKey = 'import_mode';
  static const String _autoScanKey = 'auto_scan';
  static const String _watchForChangesKey = 'watch_for_changes';

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();

    final importModeIndex = prefs.getInt(_importModeKey) ?? 0;
    final importMode = ImportMode.values[importModeIndex];

    final autoScan = prefs.getBool(_autoScanKey) ?? true;
    final watchForChanges = prefs.getBool(_watchForChangesKey) ?? true;

    return SettingsState(
      importMode: importMode,
      autoScan: autoScan,
      watchForChanges: watchForChanges,
    );
  }

  Future<void> setImportMode(ImportMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_importModeKey, mode.index);

    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(importMode: mode));
    }
  }

  Future<void> setAutoScan(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScanKey, enabled);

    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(autoScan: enabled));
    }
  }

  Future<void> setWatchForChanges(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_watchForChangesKey, enabled);

    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(watchForChanges: enabled));
    }
  }
}

// Convenience providers for specific settings
@riverpod
class ImportModeNotifier extends _$ImportModeNotifier {
  @override
  ImportMode build() {
    return ref
        .watch(settingsProvider)
        .when(
          data: (settings) => settings.importMode,
          loading: () => ImportMode.mixed,
          error: (_, _) => ImportMode.mixed,
        );
  }

  Future<void> update(ImportMode mode) async {
    await ref.read(settingsProvider.notifier).setImportMode(mode);
  }
}

@riverpod
class AutoScanNotifier extends _$AutoScanNotifier {
  @override
  bool build() {
    return ref
        .watch(settingsProvider)
        .when(
          data: (settings) => settings.autoScan,
          loading: () => true,
          error: (_, _) => true,
        );
  }

  Future<void> update(bool enabled) async {
    await ref.read(settingsProvider.notifier).setAutoScan(enabled);
  }
}

@riverpod
class WatchForChangesNotifier extends _$WatchForChangesNotifier {
  @override
  bool build() {
    return ref
        .watch(settingsProvider)
        .when(
          data: (settings) => settings.watchForChanges,
          loading: () => true,
          error: (_, _) => true,
        );
  }

  Future<void> update(bool enabled) async {
    await ref.read(settingsProvider.notifier).setWatchForChanges(enabled);
  }
}
