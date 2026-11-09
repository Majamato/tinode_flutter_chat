import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/attachments/data/media_compressor.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';

/// A [MediaCompressor] that hands the file back as it was, under the
/// compressed type, and records what it was asked.
final class FakeMediaCompressor implements MediaCompressor {
  FakeMediaCompressor({
    this.info = const VideoInfo(
      duration: Duration(seconds: 10),
      width: 1280,
      height: 720,
    ),
    this.poster,
    this.imagePosterBytes,
  });

  /// What [videoInfo] says; null as if the video can't be read.
  VideoInfo? info;

  /// What [videoPoster] gives.
  Uint8List? poster;

  /// What [imagePoster] gives.
  Uint8List? imagePosterBytes;

  /// When set, a video's compression reports each fraction added and ends
  /// when it closes; else it ends at once.
  StreamController<double>? videoSteps;

  /// When set, how large the compressed video says it is.
  int? videoLength;

  /// When set, compressing throws it.
  Exception? failure;

  /// What it was asked, in order: `video <length>`, `image <length>`,
  /// `cancel`.
  final calls = <String>[];

  var _cancelled = false;

  @override
  Future<VideoInfo?> videoInfo(LocalFile video) async => info;

  @override
  Future<Uint8List?> videoPoster(LocalFile video) async => poster;

  @override
  Future<Uint8List?> imagePoster(
    LocalFile image, {
    int? width,
    int? height,
  }) async => imagePosterBytes;

  @override
  Future<CompressedMedia> compressVideo(
    LocalFile video,
    TinodeAttachmentLimits limits, {
    void Function(double fraction)? onProgress,
  }) async {
    calls.add('video ${video.length}');
    _cancelled = false;
    if (failure case final failure?) {
      throw failure;
    }
    if (videoSteps case final steps?) {
      await steps.stream.forEach((step) => onProgress?.call(step));
    }
    if (_cancelled) {
      throw const CompressionCancelledException();
    }
    return _output(video, 'video/mp4', '.mp4', length: videoLength);
  }

  @override
  Future<CompressedMedia> compressImage(
    LocalFile image,
    TinodeAttachmentLimits limits, {
    int? width,
    int? height,
  }) async {
    calls.add('image ${image.length}');
    if (failure case final failure?) {
      throw failure;
    }
    return _output(image, 'image/jpeg', '.jpg');
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
    _cancelled = true;
    if (videoSteps case final steps? when !steps.isClosed) {
      await steps.close();
    }
  }

  static CompressedMedia _output(
    LocalFile file,
    String mimeType,
    String extension, {
    int? length,
  }) => CompressedMedia(
    length: length ?? file.length,
    openRead: () => switch (file.bytes) {
      final bytes? => Stream.value(bytes),
      null => File(file.path!).openRead(),
    },
    mimeType: mimeType,
    extension: extension,
    delete: () async {},
  );
}
