// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsNotifier)
const settingsProvider = SettingsNotifierProvider._();

final class SettingsNotifierProvider
    extends $AsyncNotifierProvider<SettingsNotifier, SettingsState> {
  const SettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();
}

String _$settingsNotifierHash() => r'6dc43c0f1d6ee7b7744dae2a8557b758574473d2';

abstract class _$SettingsNotifier extends $AsyncNotifier<SettingsState> {
  FutureOr<SettingsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<SettingsState>, SettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SettingsState>, SettingsState>,
              AsyncValue<SettingsState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ImportModeNotifier)
const importModeProvider = ImportModeNotifierProvider._();

final class ImportModeNotifierProvider
    extends $NotifierProvider<ImportModeNotifier, ImportMode> {
  const ImportModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importModeNotifierHash();

  @$internal
  @override
  ImportModeNotifier create() => ImportModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportMode>(value),
    );
  }
}

String _$importModeNotifierHash() =>
    r'4a4f8d3bb378e964f1d67159a650a2d7addeab69';

abstract class _$ImportModeNotifier extends $Notifier<ImportMode> {
  ImportMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ImportMode, ImportMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImportMode, ImportMode>,
              ImportMode,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AutoScanNotifier)
const autoScanProvider = AutoScanNotifierProvider._();

final class AutoScanNotifierProvider
    extends $NotifierProvider<AutoScanNotifier, bool> {
  const AutoScanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScanNotifierHash();

  @$internal
  @override
  AutoScanNotifier create() => AutoScanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$autoScanNotifierHash() => r'e8d7c9bd7059e0117979b120616addcd5c1abb8d';

abstract class _$AutoScanNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(WatchForChangesNotifier)
const watchForChangesProvider = WatchForChangesNotifierProvider._();

final class WatchForChangesNotifierProvider
    extends $NotifierProvider<WatchForChangesNotifier, bool> {
  const WatchForChangesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchForChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchForChangesNotifierHash();

  @$internal
  @override
  WatchForChangesNotifier create() => WatchForChangesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$watchForChangesNotifierHash() =>
    r'1f15ffac52a0401b14d8cd4e04d39c69d5a2e704';

abstract class _$WatchForChangesNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
