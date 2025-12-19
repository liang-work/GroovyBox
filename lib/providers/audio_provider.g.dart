// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(audioHandler)
const audioHandlerProvider = AudioHandlerProvider._();

final class AudioHandlerProvider
    extends $FunctionalProvider<AudioHandler, AudioHandler, AudioHandler>
    with $Provider<AudioHandler> {
  const AudioHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioHandlerHash();

  @$internal
  @override
  $ProviderElement<AudioHandler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioHandler create(Ref ref) {
    return audioHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioHandler>(value),
    );
  }
}

String _$audioHandlerHash() => r'65fbd92e049fe4f3a0763516f1e68e1614f7630f';

@ProviderFor(CurrentTrackMetadataNotifier)
const currentTrackMetadataProvider = CurrentTrackMetadataNotifierProvider._();

final class CurrentTrackMetadataNotifierProvider
    extends $NotifierProvider<CurrentTrackMetadataNotifier, TrackMetadata?> {
  const CurrentTrackMetadataNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentTrackMetadataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentTrackMetadataNotifierHash();

  @$internal
  @override
  CurrentTrackMetadataNotifier create() => CurrentTrackMetadataNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackMetadata? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackMetadata?>(value),
    );
  }
}

String _$currentTrackMetadataNotifierHash() =>
    r'0a491bd4edda2b010ed3d6f7dd459f4ac8689a5f';

abstract class _$CurrentTrackMetadataNotifier
    extends $Notifier<TrackMetadata?> {
  TrackMetadata? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TrackMetadata?, TrackMetadata?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrackMetadata?, TrackMetadata?>,
              TrackMetadata?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
