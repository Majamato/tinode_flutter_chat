// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outgoing_attachment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How far the upload of message [clientId]'s attachment got, from 0 to 1;
/// null before it starts. Only the outgoing bubble's progress ring watches
/// it.

@ProviderFor(UploadProgressController)
final uploadProgressControllerProvider = UploadProgressControllerFamily._();

/// How far the upload of message [clientId]'s attachment got, from 0 to 1;
/// null before it starts. Only the outgoing bubble's progress ring watches
/// it.
final class UploadProgressControllerProvider
    extends $NotifierProvider<UploadProgressController, double?> {
  /// How far the upload of message [clientId]'s attachment got, from 0 to 1;
  /// null before it starts. Only the outgoing bubble's progress ring watches
  /// it.
  UploadProgressControllerProvider._({
    required UploadProgressControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'uploadProgressControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$uploadProgressControllerHash();

  @override
  String toString() {
    return r'uploadProgressControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  UploadProgressController create() => UploadProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UploadProgressControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$uploadProgressControllerHash() =>
    r'97cf62325bc53eb07dce6379204367ae416aab78';

/// How far the upload of message [clientId]'s attachment got, from 0 to 1;
/// null before it starts. Only the outgoing bubble's progress ring watches
/// it.

final class UploadProgressControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          UploadProgressController,
          double?,
          double?,
          double?,
          (String, String)
        > {
  UploadProgressControllerFamily._()
    : super(
        retry: null,
        name: r'uploadProgressControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How far the upload of message [clientId]'s attachment got, from 0 to 1;
  /// null before it starts. Only the outgoing bubble's progress ring watches
  /// it.

  UploadProgressControllerProvider call(String topic, String clientId) =>
      UploadProgressControllerProvider._(
        argument: (topic, clientId),
        from: this,
      );

  @override
  String toString() => r'uploadProgressControllerProvider';
}

/// How far the upload of message [clientId]'s attachment got, from 0 to 1;
/// null before it starts. Only the outgoing bubble's progress ring watches
/// it.

abstract class _$UploadProgressController extends $Notifier<double?> {
  late final _$args = ref.$arg as (String, String);
  String get topic => _$args.$1;
  String get clientId => _$args.$2;

  double? build(String topic, String clientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double?, double?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double?, double?>,
              double?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// The staged copy of an outgoing attachment, for its bubble; null once
/// it is gone.

@ProviderFor(stagedFile)
final stagedFileProvider = StagedFileFamily._();

/// The staged copy of an outgoing attachment, for its bubble; null once
/// it is gone.

final class StagedFileProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalFile?>,
          LocalFile?,
          FutureOr<LocalFile?>
        >
    with $FutureModifier<LocalFile?>, $FutureProvider<LocalFile?> {
  /// The staged copy of an outgoing attachment, for its bubble; null once
  /// it is gone.
  StagedFileProvider._({
    required StagedFileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stagedFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stagedFileHash();

  @override
  String toString() {
    return r'stagedFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LocalFile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalFile?> create(Ref ref) {
    final argument = this.argument as String;
    return stagedFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StagedFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stagedFileHash() => r'ac9d30f83ed8a2a84f500a766198198622e88559';

/// The staged copy of an outgoing attachment, for its bubble; null once
/// it is gone.

final class StagedFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LocalFile?>, String> {
  StagedFileFamily._()
    : super(
        retry: null,
        name: r'stagedFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The staged copy of an outgoing attachment, for its bubble; null once
  /// it is gone.

  StagedFileProvider call(String stagedId) =>
      StagedFileProvider._(argument: stagedId, from: this);

  @override
  String toString() => r'stagedFileProvider';
}
