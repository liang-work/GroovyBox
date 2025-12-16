// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TrackRepository)
const trackRepositoryProvider = TrackRepositoryProvider._();

final class TrackRepositoryProvider
    extends $AsyncNotifierProvider<TrackRepository, void> {
  const TrackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackRepositoryHash();

  @$internal
  @override
  TrackRepository create() => TrackRepository();
}

String _$trackRepositoryHash() => r'244e5fc82fcaa34cb1276a41e4158a0eefcc7258';

abstract class _$TrackRepository extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
