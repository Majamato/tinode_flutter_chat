import 'package:meta/meta.dart';

/// Where the user picks what to send.
enum AttachmentSource {
  /// A photo from the gallery, sent as an image.
  gallery,

  /// A new photo from the camera, sent as an image.
  camera,

  /// Any file, sent as a file.
  file,
}

/// A file the user picked to send, before it is staged.
@immutable
final class PickedFile {
  const PickedFile({
    required this.name,
    required this.length,
    required this.openRead,
    this.mimeType,
    this.path,
    this.isImage = false,
  });

  final String name;

  /// The size in bytes.
  final int length;

  /// Reads the file; it may be called more than once.
  final Stream<List<int>> Function() openRead;
  final String? mimeType;

  /// Where it is on disk, for a preview; null when it isn't a plain file.
  final String? path;

  /// Sent as an image shown in the message, rather than as a file.
  final bool isImage;
}
