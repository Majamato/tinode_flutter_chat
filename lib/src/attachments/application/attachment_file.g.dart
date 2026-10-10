// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_file.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The file [fileRef] names, on this device: from the cache, or downloaded
/// into it once, however many widgets watch it. Images and photos given
/// by ref watch it.
///
/// A failed download, e.g. offline, is an error; it loads again on the
/// next connect.

@ProviderFor(attachmentFile)
final attachmentFileProvider = AttachmentFileFamily._();

/// The file [fileRef] names, on this device: from the cache, or downloaded
/// into it once, however many widgets watch it. Images and photos given
/// by ref watch it.
///
/// A failed download, e.g. offline, is an error; it loads again on the
/// next connect.

final class AttachmentFileProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalFile>,
          LocalFile,
          FutureOr<LocalFile>
        >
    with $FutureModifier<LocalFile>, $FutureProvider<LocalFile> {
  /// The file [fileRef] names, on this device: from the cache, or downloaded
  /// into it once, however many widgets watch it. Images and photos given
  /// by ref watch it.
  ///
  /// A failed download, e.g. offline, is an error; it loads again on the
  /// next connect.
  AttachmentFileProvider._({
    required AttachmentFileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'attachmentFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attachmentFileHash();

  @override
  String toString() {
    return r'attachmentFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LocalFile> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalFile> create(Ref ref) {
    final argument = this.argument as String;
    return attachmentFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attachmentFileHash() => r'069db4f157c6b11128e21985c850a74bb5220a92';

/// The file [fileRef] names, on this device: from the cache, or downloaded
/// into it once, however many widgets watch it. Images and photos given
/// by ref watch it.
///
/// A failed download, e.g. offline, is an error; it loads again on the
/// next connect.

final class AttachmentFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LocalFile>, String> {
  AttachmentFileFamily._()
    : super(
        retry: null,
        name: r'attachmentFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The file [fileRef] names, on this device: from the cache, or downloaded
  /// into it once, however many widgets watch it. Images and photos given
  /// by ref watch it.
  ///
  /// A failed download, e.g. offline, is an error; it loads again on the
  /// next connect.

  AttachmentFileProvider call(String fileRef) =>
      AttachmentFileProvider._(argument: fileRef, from: this);

  @override
  String toString() => r'attachmentFileProvider';
}
