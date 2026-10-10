import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:mime/mime.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';

/// Lets the user choose a photo or a file to send.
abstract interface class AttachmentPicker {
  /// Whether this device can take a photo here; desktops can't.
  bool get hasCamera;

  /// What the user picked from [source]; null when they cancelled.
  Future<PickedFile?> pick(AttachmentSource source);
}

/// [AttachmentPicker] over `image_picker` and `file_picker`. Photos are
/// scaled down to about 2048 px at quality 85 where the platform can (not
/// on desktops).
final class PluginAttachmentPicker implements AttachmentPicker {
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
        return image == null ? null : _picked(image, isImage: true);
      case AttachmentSource.file:
        final file = await FilePicker.pickFile();
        return file == null ? null : _picked(file.xFile, isImage: false);
    }
  }

  static Future<PickedFile> _picked(XFile file, {required bool isImage}) async {
    final mimeType =
        file.mimeType ?? lookupMimeType(file.name) ?? lookupMimeType(file.path);
    return PickedFile(
      name: file.name,
      length: await file.length(),
      openRead: () => file.openRead(),
      mimeType: mimeType,
      path: file.path.isEmpty ? null : file.path,
      // A gallery item that isn't a picture (some return videos) goes as a
      // file.
      isImage: isImage && (mimeType?.startsWith('image/') ?? true),
    );
  }
}
