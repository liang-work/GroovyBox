// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(metadataService)
const metadataServiceProvider = MetadataServiceProvider._();

final class MetadataServiceProvider
    extends
        $FunctionalProvider<MetadataService, MetadataService, MetadataService>
    with $Provider<MetadataService> {
  const MetadataServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metadataServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metadataServiceHash();

  @$internal
  @override
  $ProviderElement<MetadataService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MetadataService create(Ref ref) {
    return metadataService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetadataService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetadataService>(value),
    );
  }
}

String _$metadataServiceHash() => r'62471f009f532ce97bab1ea7e87171ae385592b7';

@ProviderFor(trackMetadata)
const trackMetadataProvider = TrackMetadataFamily._();

final class TrackMetadataProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrackMetadata>,
          TrackMetadata,
          FutureOr<TrackMetadata>
        >
    with $FutureModifier<TrackMetadata>, $FutureProvider<TrackMetadata> {
  const TrackMetadataProvider._({
    required TrackMetadataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'trackMetadataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trackMetadataHash();

  @override
  String toString() {
    return r'trackMetadataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrackMetadata> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrackMetadata> create(Ref ref) {
    final argument = this.argument as String;
    return trackMetadata(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrackMetadataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trackMetadataHash() => r'9833c87e90297f7c9aa952c31f78a73aae78422b';

final class TrackMetadataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrackMetadata>, String> {
  const TrackMetadataFamily._()
    : super(
        retry: null,
        name: r'trackMetadataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrackMetadataProvider call(String path) =>
      TrackMetadataProvider._(argument: path, from: this);

  @override
  String toString() => r'trackMetadataProvider';
}
