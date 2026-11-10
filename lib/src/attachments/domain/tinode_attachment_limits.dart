import 'dart:math' show max, min;

import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// How `TinodeChat` shrinks the photos and videos the user sends, and how
/// large a video may be once shrunk.
///
/// Photos are scaled down to [maxPhotoSide] pixels on their longer side
/// and saved as JPEG at [photoQuality]. A video within [maxVideoBytes] (or
/// the server's own limit, when lower) goes as it is. One over it is
/// re-encoded at about 720p, [videoBitrate] and [audioBitrate] (on
/// Android at about 480p and 80% of [videoBitrate]), and may then weigh
/// 10% more (see [compressedVideoBytesLimit]). Some encoders
/// won't go that low, so one still over is re-encoded once more,
/// at about 480p and a bitrate cut by as much as it overshot (see
/// [secondPassVideoBitrate]), and not sent if it is still over. Of one that
/// can't fit at those bitrates only a part can be sent: see [maxClip].
///
/// A picked video over [maxSourceVideoBytes] or [maxSourceVideoDuration] is
/// refused before anything is copied: a movie is not for a chat.
final class TinodeAttachmentLimits with ValueObject {
  /// Creates the limits; by default 20 MiB per video, at 1.5 Mbit/s and
  /// 128 kbit/s of sound, picked videos of up to 500 MiB and 10 minutes,
  /// and photos of 2048 px at quality 85.
  const TinodeAttachmentLimits({
    this.maxVideoBytes = 20 * 1024 * 1024,
    this.videoBitrate = 1500000,
    this.audioBitrate = 128000,
    this.maxSourceVideoBytes = 500 * 1024 * 1024,
    this.maxSourceVideoDuration = const Duration(minutes: 10),
    this.maxPhotoSide = 2048,
    this.photoQuality = 85,
  }) : assert(maxVideoBytes > 0, 'a video needs some room'),
       assert(maxSourceVideoBytes > 0, 'a picked video needs some room'),
       assert(videoBitrate > 0 && audioBitrate >= 0, 'bitrates are positive'),
       assert(maxPhotoSide > 0, 'a photo needs some pixels'),
       assert(photoQuality > 0 && photoQuality <= 100, 'quality is 1..100');

  /// The largest video sent, in bytes.
  final int maxVideoBytes;

  /// The video's bitrate after compression, in bits per second.
  final int videoBitrate;

  /// The sound's bitrate after compression, in bits per second.
  final int audioBitrate;

  /// The largest video that can be picked, in bytes, before compression.
  final int maxSourceVideoBytes;

  /// The longest video that can be picked.
  final Duration maxSourceVideoDuration;

  /// The longer side of a sent photo, in pixels.
  final int maxPhotoSide;

  /// The JPEG quality of a sent photo, 1 to 100.
  final int photoQuality;

  /// What is left of the limit for the encoder's overhead.
  static const _headroom = 0.9;

  /// The limit a video must fit: [maxVideoBytes], or [serverLimit] when it
  /// is lower. Compression aims at it.
  int videoBytesLimit(int? serverLimit) =>
      serverLimit == null ? maxVideoBytes : min(maxVideoBytes, serverLimit);

  /// How far past [maxVideoBytes] a compressed video may still go, for an
  /// encoder that misses its bitrate.
  static const _tolerance = 1.1;

  /// The most a compressed video may weigh: [maxVideoBytes] and 10% more
  /// (22 MiB by default), for an encoder that misses its bitrate; never
  /// more than [serverLimit].
  int compressedVideoBytesLimit(int? serverLimit) {
    final ceiling = (maxVideoBytes * _tolerance).floor();
    return serverLimit == null ? ceiling : min(ceiling, serverLimit);
  }

  /// The lowest video bitrate asked for, in bits per second.
  static const _minVideoBitrate = 100000;

  /// The longest video that fits [bytes] at these bitrates.
  Duration maxVideoDurationFor(int bytes) => Duration(
    milliseconds: (bytes * 8 * _headroom * 1000 / (videoBitrate + audioBitrate))
        .floor(),
  );

  /// The longest video that fits [maxVideoBytes]: what the camera records
  /// at most.
  Duration get maxVideoDuration => maxVideoDurationFor(maxVideoBytes);

  /// The longest part that can be chosen of a video of [duration] and
  /// [fileBytes]: all of it when it is within the limit, as it goes as it
  /// is; else as much as fits once compressed, with the encoder's headroom.
  Duration maxClip({
    required int fileBytes,
    required Duration duration,
    int? serverLimit,
  }) {
    final limit = videoBytesLimit(serverLimit);
    if (fileBytes <= limit) {
      return duration;
    }
    final fits = maxVideoDurationFor(limit);
    return fits < duration ? fits : duration;
  }

  /// The video bitrate for a part of a video of [sourceBytes] and
  /// [sourceDuration]: [videoBitrate], or the source's own when that is
  /// lower, since a trimmed copy shouldn't grow past what it came from.
  int trimmedVideoBitrate(int sourceBytes, Duration sourceDuration) {
    final millis = sourceDuration.inMilliseconds;
    if (millis <= 0) {
      return videoBitrate;
    }
    final source = sourceBytes * 8000 ~/ millis - audioBitrate;
    return min(videoBitrate, max(source, _minVideoBitrate));
  }

  /// The video bitrate to ask for in the second, smaller pass over a video
  /// of [duration] whose first pass, asked for [asked], came out at
  /// [outputBytes], over [limitBytes]. It is cut by as much as the encoder
  /// overshot, so that the result fits with the encoder's headroom; never
  /// more than [asked].
  int secondPassVideoBitrate({
    required int asked,
    required int outputBytes,
    required Duration duration,
    required int limitBytes,
  }) {
    final millis = duration.inMilliseconds;
    if (millis <= 0 || outputBytes <= 0) {
      return asked;
    }
    final got = outputBytes * 8000 / millis - audioBitrate;
    final wanted = limitBytes * 8000 * _headroom / millis - audioBitrate;
    if (got <= 0 || wanted <= 0) {
      return _minVideoBitrate;
    }
    return (asked * wanted / got).floor().clamp(_minVideoBitrate, asked);
  }

  /// About how large a video of [duration] and [originalBytes] is once
  /// compressed: no larger than it was, nor than its bitrates allow.
  int estimatedVideoBytes(Duration duration, int originalBytes) => min(
    originalBytes,
    (duration.inMilliseconds * (videoBitrate + audioBitrate) / 8000).ceil(),
  );

  @override
  List<Object?> get props => [
    maxVideoBytes,
    videoBitrate,
    audioBitrate,
    maxSourceVideoBytes,
    maxSourceVideoDuration,
    maxPhotoSide,
    photoQuality,
  ];
}
