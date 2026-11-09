import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart'
    hide PickedFile;
import 'package:mime/mime.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';

/// Lets the user choose a photo, a video or a file to send.
abstract interface class AttachmentPicker {
  /// Whether this device can take a photo here; desktops can't.
  bool get hasCamera;

  /// What the user picked from [source]; null when they cancelled.
  Future<PickedFile?> pick(AttachmentSource source);

  /// The photo or video the in-app camera took, at [path].
  Future<PickedFile> captured(String path, {required bool isVideo});
}

/// [AttachmentPicker] over `image_picker` and `file_picker`. A profile's
/// photos ([AttachmentSource.gallery] and [AttachmentSource.camera]) are
/// scaled down to about 2048 px at quality 85 where the platform can (not on
/// desktops); the chat's photos and videos ([AttachmentSource.media]) come
/// as they are, for the outbox to compress.
///
/// On Android, photos and videos come from the system photo picker, a sheet
/// over the app, rather than the file picker `image_picker` opens by
/// default; [AttachmentSource.file] keeps the file picker, for any file.
final class PluginAttachmentPicker implements AttachmentPicker {
  PluginAttachmentPicker() {
    if (ImagePickerPlatform.instance case final ImagePickerAndroid android) {
      android.useAndroidPhotoPicker = true;
    }
  }

  static const _maxSide = 2048.0;
  static const _quality = 85;

  final _images = ImagePicker();

  @override
  bool get hasCamera => _images.supportsImageSource(ImageSource.camera);

  @override
  Future<PickedFile?> pick(AttachmentSource source) async {
    switch (source) {
      case AttachmentSource.gallery || AttachmentSource.camera:
        final image = await _images.pickImage(
          source: source == AttachmentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: _maxSide,
          maxHeight: _maxSide,
          imageQuality: _quality,
        );
        return image == null ? null : _picked(image, _Kind.photo);
      case AttachmentSource.media:
        final media = await _images.pickMedia(requestFullMetadata: false);
        return media == null ? null : _picked(media, _Kind.media);
      case AttachmentSource.file:
        final file = await FilePicker.pickFile();
        return file == null ? null : _picked(file.xFile, _Kind.file);
    }
  }

  @override
  Future<PickedFile> captured(String path, {required bool isVideo}) =>
      _picked(XFile(path), isVideo ? _Kind.video : _Kind.photo);

  /// [file] as picked of [kind]. A photo that isn't a picture (some
  /// galleries return videos) and media that is neither go as files.
  static Future<PickedFile> _picked(XFile file, _Kind kind) async {
    final mimeType =
        file.mimeType ?? lookupMimeType(file.name) ?? lookupMimeType(file.path);
    final isVideo = switch (kind) {
      _Kind.video => true,
      _Kind.media => mimeType?.startsWith('video/') ?? false,
      _Kind.photo || _Kind.file => false,
    };
    final isImage = switch (kind) {
      _Kind.photo => mimeType?.startsWith('image/') ?? true,
      _Kind.media => mimeType?.startsWith('image/') ?? false,
      _Kind.video || _Kind.file => false,
    };
    return PickedFile(
      name: file.name,
      length: await file.length(),
      openRead: () => file.openRead(),
      mimeType: mimeType ?? (isVideo ? 'video/mp4' : null),
      path: file.path.isEmpty ? null : file.path,
      isImage: isImage,
      isVideo: isVideo,
    );
  }
}

/// What a picker hands back: a photo, a photo or a video, a video, or any
/// file.
enum _Kind { photo, media, video, file }
