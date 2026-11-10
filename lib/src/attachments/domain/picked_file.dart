import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';

/// Where the user picks what to send.
enum AttachmentSource {
  /// A photo from the gallery, sent as an image, scaled down as picked.
  gallery,

  /// A new photo from the system's camera, sent as an image, scaled down as
  /// taken.
  camera,

  /// A photo or a video from the gallery (Photos on iOS), as picked; the
  /// chat compresses it before it goes.
  media,

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
    this.isVideo = false,
    this.voice,
  });

  final String name;

  /// The size in bytes.
  final int length;

  /// Reads the file; it may be called more than once.
  final Stream<List<int>> Function() openRead;
  final String? mimeType;

  /// Where it is on disk, for a preview; null when it isn't a plain file.
  final String? path;

  /// Sent as an image shown in the message, rather than as a file. It is
  /// compressed before it goes.
  final bool isImage;

  /// Sent as a video played in the message, rather than as a file. It must
  /// fit `TinodeAttachmentLimits`, compressed first only if it is over.
  final bool isVideo;

  /// Set for a voice message: sent as a recording to play, rather than as
  /// a file.
  final VoiceNote? voice;

  /// This recording as a voice message described by [note].
  PickedFile withVoice(VoiceNote note) => PickedFile(
    name: name,
    length: length,
    openRead: openRead,
    mimeType: mimeType,
    path: path,
    voice: note,
  );
}
