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
    r'eaf3dcf7c74dc24d6ebe14840d597e4a79859a63';

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

String _$autoScanNotifierHash() => r'56f2f1a2f6aef095782a0ed4407a43a8f589dc4b';

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
    r'b4648380ae989e6e36138780d0c925916b6e20b3';

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
