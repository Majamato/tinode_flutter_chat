// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outgoing_attachment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How far message [clientId]'s attachment got: compressing, then
/// uploading; null before either reports. Only the outgoing bubble's
/// progress overlay and ring watch it.

@ProviderFor(AttachmentProgressController)
final attachmentProgressControllerProvider =
    AttachmentProgressControllerFamily._();

/// How far message [clientId]'s attachment got: compressing, then
/// uploading; null before either reports. Only the outgoing bubble's
/// progress overlay and ring watch it.
final class AttachmentProgressControllerProvider
    extends
        $NotifierProvider<AttachmentProgressController, AttachmentProgress?> {
  /// How far message [clientId]'s attachment got: compressing, then
  /// uploading; null before either reports. Only the outgoing bubble's
  /// progress overlay and ring watch it.
  AttachmentProgressControllerProvider._({
    required AttachmentProgressControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'attachmentProgressControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attachmentProgressControllerHash();

  @override
  String toString() {
    return r'attachmentProgressControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AttachmentProgressController create() => AttachmentProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttachmentProgress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentProgressControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attachmentProgressControllerHash() =>
    r'e36edfc6261ec7457208fd9f2fae10385d735600';

/// How far message [clientId]'s attachment got: compressing, then
/// uploading; null before either reports. Only the outgoing bubble's
/// progress overlay and ring watch it.

final class AttachmentProgressControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AttachmentProgressController,
          AttachmentProgress?,
          AttachmentProgress?,
          AttachmentProgress?,
          (String, String)
        > {
  AttachmentProgressControllerFamily._()
    : super(
        retry: null,
        name: r'attachmentProgressControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How far message [clientId]'s attachment got: compressing, then
  /// uploading; null before either reports. Only the outgoing bubble's
  /// progress overlay and ring watch it.

  AttachmentProgressControllerProvider call(String topic, String clientId) =>
      AttachmentProgressControllerProvider._(
        argument: (topic, clientId),
        from: this,
      );

  @override
  String toString() => r'attachmentProgressControllerProvider';
}

/// How far message [clientId]'s attachment got: compressing, then
/// uploading; null before either reports. Only the outgoing bubble's
/// progress overlay and ring watch it.

abstract class _$AttachmentProgressController
    extends $Notifier<AttachmentProgress?> {
  late final _$args = ref.$arg as (String, String);
  String get topic => _$args.$1;
  String get clientId => _$args.$2;

  AttachmentProgress? build(String topic, String clientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AttachmentProgress?, AttachmentProgress?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AttachmentProgress?, AttachmentProgress?>,
              AttachmentProgress?,
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
