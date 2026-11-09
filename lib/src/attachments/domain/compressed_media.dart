import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What a video plays like: how long, and its size in pixels as shown
/// (rotation applied).
final class VideoInfo with ValueObject {
  const VideoInfo({required this.duration, this.width, this.height});

  final Duration duration;
  final int? width;
  final int? height;

  @override
  List<Object?> get props => [duration, width, height];
}

/// A photo or video once compressed: a temporary file of [length] bytes,
/// read with [openRead], of [mimeType], and its size in pixels when known.
/// [delete] removes it once it is staged.
final class CompressedMedia {
  const CompressedMedia({
    required this.length,
    required this.openRead,
    required this.mimeType,
    required this.extension,
    required this.delete,
    this.width,
    this.height,
  });

  final int length;
  final Stream<List<int>> Function() openRead;
  final String mimeType;

  /// The file name's extension, with its dot, e.g. `.mp4`.
  final String extension;
  final Future<void> Function() delete;
  final int? width;
  final int? height;
}

/// The compression was stopped, e.g. its message was discarded.
final class CompressionCancelledException implements Exception {
  const CompressionCancelledException();

  @override
  String toString() => 'CompressionCancelledException()';
}
