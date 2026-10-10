// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_download_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opening a received file: its download progress, then the file. Only
/// the file's bubble watches it.

@ProviderFor(FileDownloadController)
final fileDownloadControllerProvider = FileDownloadControllerFamily._();

/// Opening a received file: its download progress, then the file. Only
/// the file's bubble watches it.
final class FileDownloadControllerProvider
    extends $NotifierProvider<FileDownloadController, FileDownloadState> {
  /// Opening a received file: its download progress, then the file. Only
  /// the file's bubble watches it.
  FileDownloadControllerProvider._({
    required FileDownloadControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fileDownloadControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fileDownloadControllerHash();

  @override
  String toString() {
    return r'fileDownloadControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FileDownloadController create() => FileDownloadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileDownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileDownloadState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FileDownloadControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fileDownloadControllerHash() =>
    r'f5fba41cf76629ae1322657cbff2da846c03f50e';

/// Opening a received file: its download progress, then the file. Only
/// the file's bubble watches it.

final class FileDownloadControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FileDownloadController,
          FileDownloadState,
          FileDownloadState,
          FileDownloadState,
          String
        > {
  FileDownloadControllerFamily._()
    : super(
        retry: null,
        name: r'fileDownloadControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Opening a received file: its download progress, then the file. Only
  /// the file's bubble watches it.

  FileDownloadControllerProvider call(String fileRef) =>
      FileDownloadControllerProvider._(argument: fileRef, from: this);

  @override
  String toString() => r'fileDownloadControllerProvider';
}

/// Opening a received file: its download progress, then the file. Only
/// the file's bubble watches it.

abstract class _$FileDownloadController extends $Notifier<FileDownloadState> {
  late final _$args = ref.$arg as String;
  String get fileRef => _$args;

  FileDownloadState build(String fileRef);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FileDownloadState, FileDownloadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FileDownloadState, FileDownloadState>,
              FileDownloadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
