import 'dart:io';
import 'dart:math' show max, min;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/image_size.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
import 'package:v_video_compressor/v_video_compressor.dart';

/// Shrinks photos and videos before they are sent, and reads what a video
/// is. One compression runs at a time: the outbox asks for no more.
abstract interface class MediaCompressor {
  /// How long [video] plays and its size; null when it can't be read.
  Future<VideoInfo?> videoInfo(LocalFile video);

  /// A small JPEG still of [video], at most 640 px on its longer side;
  /// null when none can be taken.
  Future<Uint8List?> videoPoster(LocalFile video);

  /// A small upright JPEG of [image], at most 640 px on its longer side,
  /// for its bubble while it is sent; null when none can be made. [width]
  /// and [height], when known, are its size as shown.
  Future<Uint8List?> imagePoster(LocalFile image, {int? width, int? height});

  /// [video] re-encoded as MP4 at the [limits]' bitrates, reporting how far
  /// it got to [onProgress] (0 to 1). Throws
  /// [CompressionCancelledException] after [cancel].
  Future<CompressedMedia> compressVideo(
    LocalFile video,
    TinodeAttachmentLimits limits, {
    void Function(double fraction)? onProgress,
  });

  /// [image] as a JPEG no larger than the [limits] allow. [width] and
  /// [height], when known, are its size as shown.
  Future<CompressedMedia> compressImage(
    LocalFile image,
    TinodeAttachmentLimits limits, {
    int? width,
    int? height,
  });

  /// Stops the compression under way, if any.
  Future<void> cancel();
}

/// [MediaCompressor] over `v_video_compressor` (Media3 on Android,
/// AVFoundation on iOS) and `flutter_image_compress`.
final class PluginMediaCompressor implements MediaCompressor {
  final _videos = VVideoCompressor();
  var _cancelled = false;

  /// The poster's longer side, in pixels: sharp in a bubble on most
  /// screens, yet a few tens of KB inline in the message.
  static const _posterSide = 640;
  static const _posterQuality = 60;

  @override
  Future<VideoInfo?> videoInfo(LocalFile video) async {
    final info = await _videos.getVideoInfo(await _pathOf(video, '.mp4'));
    if (info == null) {
      return null;
    }
    return VideoInfo(
      duration: Duration(milliseconds: info.durationMillis),
      width: info.width > 0 ? info.width : null,
      height: info.height > 0 ? info.height : null,
    );
  }

  @override
  Future<Uint8List?> videoPoster(LocalFile video) async {
    // The plugin draws iOS stills at the screen's scale (3x on most
    // iPhones), so it gives a lossless frame and the size is set here,
    // where both platforms draw at 1x.
    final frame = await _videos.getVideoThumbnail(
      await _pathOf(video, '.mp4'),
      const VVideoThumbnailConfig(
        maxWidth: _posterSide,
        maxHeight: _posterSide,
        format: VThumbnailFormat.png,
      ),
    );
    if (frame == null) {
      return null;
    }
    final file = File(frame.thumbnailPath);
    try {
      final bytes = await file.readAsBytes();
      final size = imageSizeOf(bytes);
      final shortSide = _shortSide(size?.width, size?.height, _posterSide);
      return await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: shortSide,
        minHeight: shortSide,
        quality: _posterQuality,
      );
    } finally {
      await _deleteQuietly(file);
    }
  }

  @override
  Future<Uint8List?> imagePoster(
    LocalFile image, {
    int? width,
    int? height,
  }) async {
    final shortSide = _shortSide(width, height, _posterSide);
    // The compressor turns the picture upright from its EXIF orientation.
    return switch (image.path) {
      final path? => await FlutterImageCompress.compressWithFile(
        path,
        minWidth: shortSide,
        minHeight: shortSide,
        quality: _posterQuality,
      ),
      null => await FlutterImageCompress.compressWithList(
        image.bytes!,
        minWidth: shortSide,
        minHeight: shortSide,
        quality: _posterQuality,
      ),
    };
  }

  @override
  Future<CompressedMedia> compressVideo(
    LocalFile video,
    TinodeAttachmentLimits limits, {
    void Function(double fraction)? onProgress,
  }) async {
    _cancelled = false;
    final result = await _videos.compressVideo(
      await _pathOf(video, '.mp4'),
      VVideoCompressionConfig.medium(
        // The receiver must be able to play it: always H.264 in MP4.
        fallbackToOriginalIfNotSmaller: false,
        advanced: VVideoAdvancedConfig(
          videoBitrate: limits.videoBitrate,
          audioBitrate: limits.audioBitrate,
          videoCodec: VVideoCodec.h264,
          audioCodec: VAudioCodec.aac,
          // Media3 already turns the frames by the video's rotation, so on
          // Android this would turn a portrait video on its side.
          autoCorrectOrientation: Platform.isIOS,
        ),
      ),
      onProgress: onProgress,
    );
    if (_cancelled) {
      if (result != null) {
        await _deleteQuietly(File(result.compressedFilePath));
      }
      throw const CompressionCancelledException();
    }
    if (result == null) {
      throw StateError('The video could not be compressed.');
    }
    final file = File(result.compressedFilePath);
    final info = await _videos.getVideoInfo(file.path);
    return CompressedMedia(
      length: await file.length(),
      openRead: file.openRead,
      mimeType: 'video/mp4',
      extension: '.mp4',
      delete: () => _deleteQuietly(file),
      width: (info?.width ?? 0) > 0 ? info!.width : null,
      height: (info?.height ?? 0) > 0 ? info!.height : null,
    );
  }

  @override
  Future<CompressedMedia> compressImage(
    LocalFile image,
    TinodeAttachmentLimits limits, {
    int? width,
    int? height,
  }) async {
    final temp = await getTemporaryDirectory();
    final target =
        '${temp.path}/tinode_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final shortSide = _shortSide(width, height, limits.maxPhotoSide);
    final result = await FlutterImageCompress.compressAndGetFile(
      await _pathOf(image, '.jpg'),
      target,
      minWidth: shortSide,
      minHeight: shortSide,
      quality: limits.photoQuality,
    );
    if (result == null) {
      throw StateError('The photo could not be compressed.');
    }
    final file = File(result.path);
    return CompressedMedia(
      length: await file.length(),
      openRead: file.openRead,
      mimeType: 'image/jpeg',
      extension: '.jpg',
      delete: () => _deleteQuietly(file),
    );
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    await _videos.cancelCompression();
  }

  /// The minimum to give `flutter_image_compress` so that an image of
  /// [width] by [height] ends with its longer side at most [maxSide].
  ///
  /// The compressor scales, never up, until both sides reach the minimums
  /// given; giving the same one for both makes the shorter side that long,
  /// whichever way the image is turned. An unknown size is taken as 4:3.
  static int _shortSide(int? width, int? height, int maxSide) =>
      switch ((width, height)) {
        (final w?, final h?) when w > 0 && h > 0 =>
          max(w, h) <= maxSide
              ? min(w, h)
              : (maxSide * min(w, h) / max(w, h)).round(),
        _ => maxSide * 3 ~/ 4,
      };

  /// Where [file] is on disk; one kept in memory is written out first.
  static Future<String> _pathOf(LocalFile file, String extension) async {
    if (file.path case final path?) {
      return path;
    }
    final temp = await getTemporaryDirectory();
    final copy = File(
      '${temp.path}/tinode_${DateTime.now().microsecondsSinceEpoch}'
      '$extension',
    );
    await copy.writeAsBytes(file.bytes!);
    return copy.path;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone; the OS clears its temporary folder anyway.
    }
  }
}
