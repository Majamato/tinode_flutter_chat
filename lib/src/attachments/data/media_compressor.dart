import 'dart:io';
import 'dart:math' show max, min;

import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/image_size.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:v_video_compressor/v_video_compressor.dart';
import 'package:v_video_compressor/v_video_compressor_method_channel.dart';

/// Shrinks photos and videos before they are sent, and reads what a video
/// is. One compression runs at a time: the outbox asks for no more.
abstract interface class MediaCompressor {
  /// How long [video] plays and its size; null when it can't be read.
  Future<VideoInfo?> videoInfo(LocalFile video);

  /// A small JPEG still of [video] from [at], at most 640 px on its longer
  /// side; null when none can be taken.
  Future<Uint8List?> videoPoster(
    LocalFile video, {
    Duration at = Duration.zero,
  });

  /// [count] tiny JPEG stills of [video], of [duration], evenly spread, one
  /// after the other as they are taken; null for one that can't be.
  Stream<Uint8List?> videoFrames(
    LocalFile video, {
    required int count,
    required Duration duration,
  });

  /// A small upright JPEG of [image], at most 640 px on its longer side,
  /// for its bubble while it is sent; null when none can be made. [width]
  /// and [height], when known, are its size as shown.
  Future<Uint8List?> imagePoster(LocalFile image, {int? width, int? height});

  /// [video], or only its [trim] part, re-encoded as MP4 at about 720p,
  /// or 480p when [smaller] or on Android, and at the [limits]' bitrates,
  /// or [videoBitrate] for the picture when given. Reports how far it got to
  /// [onProgress] (0 to 1). Throws [CompressionCancelledException] after
  /// [cancel].
  Future<CompressedMedia> compressVideo(
    LocalFile video,
    TinodeAttachmentLimits limits, {
    VideoTrim? trim,
    int? videoBitrate,
    bool smaller = false,
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
  /// Creates the compressor. When [startsLow] (by default on Android), a
  /// video is compressed at about 480p from the start: some Android phones
  /// won't encode 720p as low as asked, and would need a second pass.
  PluginMediaCompressor({bool? startsLow})
    : _startsLow = startsLow ?? Platform.isAndroid;

  final bool _startsLow;
  final _videos = VVideoCompressor();
  var _cancelled = false;

  /// The poster's longer side, in pixels: sharp in a bubble on most
  /// screens, yet a few tens of KB inline in the message.
  static const _posterSide = 640;
  static const _posterQuality = 60;

  /// A frame's longer side, in pixels: it shows about 40 px tall.
  static const _frameSide = 96;

  /// What is asked of the video bitrate in a first pass at about 480p: a
  /// phone that won't go as low as asked still comes out within the limit.
  static const _lowFirstPassScale = 0.8;

  /// Whether a pass is at about 480p, and the video bitrate it asks for,
  /// from [bitrate]: at 480p when [smaller] or [startsLow], and at 80% of
  /// [bitrate] in a first pass that [startsLow]. A second pass, [smaller],
  /// comes with its bitrate already cut.
  static ({bool low, int bitrate}) videoPass({
    required bool startsLow,
    required bool smaller,
    required int bitrate,
  }) => (
    low: smaller || startsLow,
    bitrate: startsLow && !smaller
        ? (bitrate * _lowFirstPassScale).floor()
        : bitrate,
  );

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
  Future<Uint8List?> videoPoster(
    LocalFile video, {
    Duration at = Duration.zero,
  }) async {
    // The plugin draws iOS stills at the screen's scale (3x on most
    // iPhones), so it gives a lossless frame and the size is set here,
    // where both platforms draw at 1x.
    final frame = await _videos.getVideoThumbnail(
      await _pathOf(video, '.mp4'),
      VVideoThumbnailConfig(
        timeMs: at.inMilliseconds,
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
  Stream<Uint8List?> videoFrames(
    LocalFile video, {
    required int count,
    required Duration duration,
  }) async* {
    final path = await _pathOf(video, '.mp4');
    for (var i = 0; i < count; i++) {
      final frame = await _videos.getVideoThumbnail(
        path,
        VVideoThumbnailConfig(
          timeMs: duration.inMilliseconds * (2 * i + 1) ~/ (2 * count),
          maxWidth: _frameSide,
          maxHeight: _frameSide,
          quality: _posterQuality,
        ),
      );
      if (frame == null) {
        yield null;
        continue;
      }
      final file = File(frame.thumbnailPath);
      try {
        yield await file.readAsBytes();
      } finally {
        await _deleteQuietly(file);
      }
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
    VideoTrim? trim,
    int? videoBitrate,
    bool smaller = false,
    void Function(double fraction)? onProgress,
  }) async {
    _cancelled = false;
    final path = await _pathOf(video, '.mp4');
    var bitrate = videoBitrate ?? limits.videoBitrate;
    if (videoBitrate == null && trim != null) {
      if (await _videos.getVideoInfo(path) case final source?) {
        bitrate = limits.trimmedVideoBitrate(
          video.length,
          Duration(milliseconds: source.durationMillis),
        );
      }
    }
    final pass = videoPass(
      startsLow: _startsLow,
      smaller: smaller,
      bitrate: bitrate,
    );
    bitrate = pass.bitrate;
    final advanced = VVideoAdvancedConfig(
      videoBitrate: bitrate,
      audioBitrate: limits.audioBitrate,
      videoCodec: VVideoCodec.h264,
      audioCodec: VAudioCodec.aac,
      // Media3 already turns the frames by the video's rotation, so on
      // Android this would turn a portrait video on its side.
      autoCorrectOrientation: Platform.isIOS,
      trimStartMs: trim?.start.inMilliseconds,
      trimEndMs: trim?.end.inMilliseconds,
    );
    // The receiver must be able to play it: always H.264 in MP4.
    final compressedPath = await _compressOnChannel(
      path,
      pass.low
          ? VVideoCompressionConfig.low(
              fallbackToOriginalIfNotSmaller: false,
              advanced: advanced,
            )
          : VVideoCompressionConfig.medium(
              fallbackToOriginalIfNotSmaller: false,
              advanced: advanced,
            ),
      onProgress,
    );
    if (_cancelled) {
      if (compressedPath != null) {
        await _deleteQuietly(File(compressedPath));
      }
      throw const CompressionCancelledException();
    }
    if (compressedPath == null) {
      throw StateError('The video could not be compressed.');
    }
    final file = File(compressedPath);
    final info = await _videos.getVideoInfo(file.path);
    return CompressedMedia(
      length: await file.length(),
      openRead: file.openRead,
      mimeType: 'video/mp4',
      extension: '.mp4',
      delete: () => _deleteQuietly(file),
      width: (info?.width ?? 0) > 0 ? info!.width : null,
      height: (info?.height ?? 0) > 0 ? info!.height : null,
      videoBitrate: bitrate,
    );
  }

  /// The plugin's own channels, as `VVideoCompressor.compressVideo` uses
  /// them: that one logs a failure and returns null, so it can't say a
  /// video's format can't be decoded.
  static final _channels = MethodChannelVVideoCompressor();

  /// Compresses the video at [path] with [config], reporting to
  /// [onProgress]; the compressed file's path, null when none came.
  /// Throws [UnsupportedVideoFormatException] when the device can't decode
  /// or encode it.
  static Future<String?> _compressOnChannel(
    String path,
    VVideoCompressionConfig config,
    void Function(double fraction)? onProgress,
  ) async {
    final progress = onProgress == null
        ? null
        : _channels.eventChannel.receiveBroadcastStream().listen((event) {
            // Not the end: on Android the plugin sends it after the
            // result, where it would land on the next compression.
            if (event case {'progress': final num fraction} when fraction < 1) {
              onProgress(fraction.toDouble());
            }
          }, onError: (Object _) {});
    try {
      // The plugin marks its channel for tests only, yet it is the one way
      // to the error: the data layer may not import Flutter's own.
      // ignore: invalid_use_of_visible_for_testing_member
      final result = await _channels.methodChannel
          .invokeMapMethod<String, Object?>('compressVideo', {
            'videoPath': path,
            'config': config.toMap(),
          });
      return switch (result?['compressedFilePath']) {
        final String compressed when compressed.isNotEmpty => compressed,
        _ => null,
      };
    } on Exception catch (e) {
      // A PlatformException, with Media3's ERROR_CODE_DECODING_
      // or ENCODING_FORMAT_UNSUPPORTED in its message.
      final reason = e.toString();
      if (reason.contains('FORMAT_UNSUPPORTED')) {
        throw UnsupportedVideoFormatException(reason);
      }
      rethrow;
    } finally {
      await progress?.cancel();
    }
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
