// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where each user's downloaded and staged files live; tests override it
/// with memory.

@ProviderFor(fileStoreOpener)
final fileStoreOpenerProvider = FileStoreOpenerProvider._();

/// Where each user's downloaded and staged files live; tests override it
/// with memory.

final class FileStoreOpenerProvider
    extends
        $FunctionalProvider<FileStoreOpener, FileStoreOpener, FileStoreOpener>
    with $Provider<FileStoreOpener> {
  /// Where each user's downloaded and staged files live; tests override it
  /// with memory.
  FileStoreOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileStoreOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileStoreOpenerHash();

  @$internal
  @override
  $ProviderElement<FileStoreOpener> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileStoreOpener create(Ref ref) {
    return fileStoreOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileStoreOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileStoreOpener>(value),
    );
  }
}

String _$fileStoreOpenerHash() => r'7dfd1d2726f37c761c532ae8c063cd7f5cea11b0';

/// How a downloaded file is opened; tests override it with a fake.

@ProviderFor(fileOpener)
final fileOpenerProvider = FileOpenerProvider._();

/// How a downloaded file is opened; tests override it with a fake.

final class FileOpenerProvider
    extends $FunctionalProvider<FileOpener, FileOpener, FileOpener>
    with $Provider<FileOpener> {
  /// How a downloaded file is opened; tests override it with a fake.
  FileOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileOpenerHash();

  @$internal
  @override
  $ProviderElement<FileOpener> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileOpener create(Ref ref) {
    return fileOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileOpener>(value),
    );
  }
}

String _$fileOpenerHash() => r'13313b3f08d06e933b8837d05fd5346c2b61c0b1';

/// How the user picks photos and files; tests override it with a fake.

@ProviderFor(attachmentPicker)
final attachmentPickerProvider = AttachmentPickerProvider._();

/// How the user picks photos and files; tests override it with a fake.

final class AttachmentPickerProvider
    extends
        $FunctionalProvider<
          AttachmentPicker,
          AttachmentPicker,
          AttachmentPicker
        >
    with $Provider<AttachmentPicker> {
  /// How the user picks photos and files; tests override it with a fake.
  AttachmentPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentPickerHash();

  @$internal
  @override
  $ProviderElement<AttachmentPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AttachmentPicker create(Ref ref) {
    return attachmentPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttachmentPicker>(value),
    );
  }
}

String _$attachmentPickerHash() => r'79e3ef3a5e4c0caec51d11d7c422fcce66e9644e';

/// How photos and videos shrink before they are sent; null where the
/// encoders aren't (desktops), and they go as picked. Tests override it
/// with a fake.

@ProviderFor(mediaCompressor)
final mediaCompressorProvider = MediaCompressorProvider._();

/// How photos and videos shrink before they are sent; null where the
/// encoders aren't (desktops), and they go as picked. Tests override it
/// with a fake.

final class MediaCompressorProvider
    extends
        $FunctionalProvider<
          MediaCompressor?,
          MediaCompressor?,
          MediaCompressor?
        >
    with $Provider<MediaCompressor?> {
  /// How photos and videos shrink before they are sent; null where the
  /// encoders aren't (desktops), and they go as picked. Tests override it
  /// with a fake.
  MediaCompressorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaCompressorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaCompressorHash();

  @$internal
  @override
  $ProviderElement<MediaCompressor?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaCompressor? create(Ref ref) {
    return mediaCompressor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaCompressor? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaCompressor?>(value),
    );
  }
}

String _$mediaCompressorHash() => r'917568eef2c518502834ff172a76f6d7437e0c19';

/// Where the in-app camera's captures are saved; tests override it with a
/// fake.

@ProviderFor(gallerySaver)
final gallerySaverProvider = GallerySaverProvider._();

/// Where the in-app camera's captures are saved; tests override it with a
/// fake.

final class GallerySaverProvider
    extends $FunctionalProvider<GallerySaver, GallerySaver, GallerySaver>
    with $Provider<GallerySaver> {
  /// Where the in-app camera's captures are saved; tests override it with a
  /// fake.
  GallerySaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gallerySaverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gallerySaverHash();

  @$internal
  @override
  $ProviderElement<GallerySaver> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GallerySaver create(Ref ref) {
    return gallerySaver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GallerySaver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GallerySaver>(value),
    );
  }
}

String _$gallerySaverHash() => r'ad3d0aeb03598fa06d98f743434aa32b7f44f0fb';

/// How photos and videos shrink, and how large a video may be;
/// `createTinodeContainer` overrides it with the host's.

@ProviderFor(tinodeAttachmentLimits)
final tinodeAttachmentLimitsProvider = TinodeAttachmentLimitsProvider._();

/// How photos and videos shrink, and how large a video may be;
/// `createTinodeContainer` overrides it with the host's.

final class TinodeAttachmentLimitsProvider
    extends
        $FunctionalProvider<
          TinodeAttachmentLimits,
          TinodeAttachmentLimits,
          TinodeAttachmentLimits
        >
    with $Provider<TinodeAttachmentLimits> {
  /// How photos and videos shrink, and how large a video may be;
  /// `createTinodeContainer` overrides it with the host's.
  TinodeAttachmentLimitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tinodeAttachmentLimitsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tinodeAttachmentLimitsHash();

  @$internal
  @override
  $ProviderElement<TinodeAttachmentLimits> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TinodeAttachmentLimits create(Ref ref) {
    return tinodeAttachmentLimits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TinodeAttachmentLimits value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TinodeAttachmentLimits>(value),
    );
  }
}

String _$tinodeAttachmentLimitsHash() =>
    r'be70a5ff603b99aa5ff30a586a457ebd8510ffc0';

/// Whether the attach menu offers the camera.

@ProviderFor(cameraAvailable)
final cameraAvailableProvider = CameraAvailableProvider._();

/// Whether the attach menu offers the camera.

final class CameraAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the attach menu offers the camera.
  CameraAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return cameraAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cameraAvailableHash() => r'9ed512a52155c31f09b863ca576512d6750fd875';
