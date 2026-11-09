import 'dart:math' show min;

import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// How `TinodeChat` shrinks the photos and videos the user sends, and how
/// large a video may be once shrunk.
///
/// Photos are scaled down to [maxPhotoSide] pixels on their longer side
/// and saved as JPEG at [photoQuality]. Videos are re-encoded at about
/// 720p, [videoBitrate] and [audioBitrate]; one still over [maxVideoBytes]
/// (or the server's own limit, when lower) is not sent. A video whose
/// length alone says it can't fit is refused before it is queued: see
/// [maxVideoDuration].
final class TinodeAttachmentLimits with ValueObject {
  /// Creates the limits; by default 20 MiB per video, at 1.5 Mbit/s and
  /// 128 kbit/s of sound, and photos of 2048 px at quality 85.
  const TinodeAttachmentLimits({
    this.maxVideoBytes = 20 * 1024 * 1024,
    this.videoBitrate = 1500000,
    this.audioBitrate = 128000,
    this.maxPhotoSide = 2048,
    this.photoQuality = 85,
  }) : assert(maxVideoBytes > 0, 'a video needs some room'),
       assert(videoBitrate > 0 && audioBitrate >= 0, 'bitrates are positive'),
       assert(maxPhotoSide > 0, 'a photo needs some pixels'),
       assert(photoQuality > 0 && photoQuality <= 100, 'quality is 1..100');

  /// The largest video sent, in bytes, after compression.
  final int maxVideoBytes;

  /// The video's bitrate after compression, in bits per second.
  final int videoBitrate;

  /// The sound's bitrate after compression, in bits per second.
  final int audioBitrate;

  /// The longer side of a sent photo, in pixels.
  final int maxPhotoSide;

  /// The JPEG quality of a sent photo, 1 to 100.
  final int photoQuality;

  /// What is left of the limit for the encoder's overhead.
  static const _headroom = 0.9;

  /// The limit a video must fit: [maxVideoBytes], or [serverLimit] when it
  /// is lower.
  int videoBytesLimit(int? serverLimit) =>
      serverLimit == null ? maxVideoBytes : min(maxVideoBytes, serverLimit);

  /// The longest video that fits [bytes] at these bitrates.
  Duration maxVideoDurationFor(int bytes) => Duration(
    milliseconds: (bytes * 8 * _headroom * 1000 / (videoBitrate + audioBitrate))
        .floor(),
  );

  /// The longest video that fits [maxVideoBytes]: what the camera records
  /// at most.
  Duration get maxVideoDuration => maxVideoDurationFor(maxVideoBytes);

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
    maxPhotoSide,
    photoQuality,
  ];
}
