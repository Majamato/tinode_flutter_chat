import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/attachments/data/media_compressor.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';

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

  /// When set, [videoPoster] waits for it, as a slow device would.
  Completer<void>? holdPoster;

  /// What [imagePoster] gives.
  Uint8List? imagePosterBytes;

  /// When set, a video's compression reports each fraction added and ends
  /// when it closes; else it ends at once.
  StreamController<double>? videoSteps;

  /// When set, how large the compressed video is: its first bytes.
  int? videoLength;

  /// When set, how large the video compressed smaller is; else
  /// [videoLength].
  int? smallerVideoLength;

  /// When set, compressing throws it.
  Exception? failure;

  /// What it was asked, in order: `video <length>`,
  /// `smaller video <length> at <bitrate>`, `image <length>`, `cancel`.
  final calls = <String>[];

  /// The part asked for of each video compressed, in order.
  final trims = <VideoTrim?>[];

  /// Where each poster of a video was taken, in order.
  final posterTimes = <Duration>[];

  var _cancelled = false;

  @override
  Future<VideoInfo?> videoInfo(LocalFile video) async => info;

  @override
  Future<Uint8List?> videoPoster(
    LocalFile video, {
    Duration at = Duration.zero,
  }) async {
    posterTimes.add(at);
    await holdPoster?.future;
    return poster;
  }

  @override
  Stream<Uint8List?> videoFrames(
    LocalFile video, {
    required int count,
    required Duration duration,
  }) => Stream.fromIterable(List.filled(count, poster));

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
    VideoTrim? trim,
    int? videoBitrate,
    bool smaller = false,
    void Function(double fraction)? onProgress,
  }) async {
    calls.add(
      smaller
          ? 'smaller video ${video.length} at $videoBitrate'
          : 'video ${video.length}',
    );
    trims.add(trim);
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
    return _output(
      video,
      'video/mp4',
      '.mp4',
      length: smaller ? smallerVideoLength ?? videoLength : videoLength,
      videoBitrate: videoBitrate ?? limits.videoBitrate,
    );
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
    int? videoBitrate,
  }) => CompressedMedia(
    length: length ?? file.length,
    openRead: () => switch (file.bytes) {
      final bytes? when length != null && length < bytes.length => Stream.value(
        bytes.sublist(0, length),
      ),
      final bytes? => Stream.value(bytes),
      null => File(file.path!).openRead(),
    },
    mimeType: mimeType,
    extension: extension,
    delete: () async {},
    videoBitrate: videoBitrate,
  );
}
