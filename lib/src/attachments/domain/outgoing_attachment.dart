import 'dart:convert';
import 'dart:typed_data';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';

/// The image, video, file or recording of a message in the outbox: the
/// staged copy to upload, what the message says about it, and, once
/// uploaded, its [ref] and when that [expires].
///
/// A photo or video is first staged as picked, [pendingCompression]; the
/// compressed copy then takes its place.
final class OutgoingAttachment with ValueObject {
  const OutgoingAttachment({
    required this.stagedId,
    required this.name,
    required this.size,
    this.mimeType,
    this.isImage = false,
    this.isVideo = false,
    this.width,
    this.height,
    this.caption = '',
    this.voice,
    this.duration,
    this.poster,
    this.pendingCompression = false,
    this.trim,
    this.ref,
    this.expires,
  });

  /// Reads what [toJson] wrote; wrong types become defaults.
  factory OutgoingAttachment.fromJson(Json json) {
    T? get<T>(String key) => switch (json[key]) {
      final T value => value,
      _ => null,
    };
    return OutgoingAttachment(
      stagedId: get('staged') ?? '',
      name: get('name') ?? '',
      size: get('size') ?? 0,
      mimeType: get('mime'),
      isImage: get('image') ?? false,
      isVideo: get('video') ?? false,
      width: get('width'),
      height: get('height'),
      caption: get('caption') ?? '',
      voice: switch (get<int>('duration')) {
        final ms? => VoiceNote(
          duration: Duration(milliseconds: ms),
          waveform: [
            for (final w in get<List<Object?>>('waveform') ?? const [])
              if (w case final int value) value,
          ],
        ),
        null => null,
      },
      duration: switch (get<int>('videoMs')) {
        final ms? => Duration(milliseconds: ms),
        null => null,
      },
      poster: switch (get<String>('poster')) {
        final data? => _decode(data),
        null => null,
      },
      pendingCompression: get('raw') ?? false,
      trim: switch ((get<int>('trimStart'), get<int>('trimEnd'))) {
        (final start?, final end?) => VideoTrim(
          Duration(milliseconds: start),
          Duration(milliseconds: end),
        ),
        _ => null,
      },
      ref: get('ref'),
      expires: switch (get<String>('expires')) {
        final time? => DateTime.tryParse(time),
        null => null,
      },
    );
  }

  /// A ref this close to expiring is uploaded again rather than sent.
  static const expiryMargin = Duration(seconds: 5);

  /// The poster's type.
  static const posterMimeType = 'image/jpeg';

  /// The staged copy, see `FileStore.stage`.
  final String stagedId;
  final String name;

  /// The size in bytes.
  final int size;
  final String? mimeType;
  final bool isImage;
  final bool isVideo;

  /// The image's or video's size in pixels, when known.
  final int? width;
  final int? height;
  final String caption;

  /// Set for a voice message, sent as a recording rather than a file.
  final VoiceNote? voice;

  /// How long a video plays; the chosen part's length when [trim] is set.
  final Duration? duration;

  /// A small JPEG of the photo or video, for its bubble while it is sent;
  /// only a video's goes inline with the message.
  final Uint8List? poster;

  /// The staged copy is the photo or video as picked, still to compress.
  final bool pendingCompression;

  /// The part of the staged video to send, cut when it is compressed.
  final VideoTrim? trim;
  final String? ref;
  final DateTime? expires;

  /// A photo or a video: shown in the bubble rather than as a file.
  bool get isMedia => isImage || isVideo;

  /// Width over height, for an image's or video's bubble.
  double get aspectRatio => imageAspectRatio(width, height);

  /// Whether it must be uploaded (again) before the message can go.
  bool needsUpload(DateTime now) =>
      ref == null ||
      (expires != null && !expires!.isAfter(now.add(expiryMargin)));

  OutgoingAttachment uploaded(String ref, DateTime expires) =>
      _copy(ref: ref, expires: expires);

  /// The compressed copy, staged as [stagedId], in place of the original.
  OutgoingAttachment compressed({
    required String stagedId,
    required String name,
    required int size,
    required String mimeType,
    int? width,
    int? height,
  }) => OutgoingAttachment(
    stagedId: stagedId,
    name: name,
    size: size,
    mimeType: mimeType,
    isImage: isImage,
    isVideo: isVideo,
    width: width ?? this.width,
    height: height ?? this.height,
    caption: caption,
    voice: voice,
    duration: duration,
    poster: poster,
  );

  /// This attachment, sent with [caption].
  OutgoingAttachment withCaption(String caption) => _copy(caption: caption);

  /// Only the [trim] part of this video, which is cut when it is
  /// compressed, with [poster] when it has a new one.
  OutgoingAttachment trimmed(VideoTrim trim, {Uint8List? poster}) => _copy(
    duration: trim.length,
    poster: poster,
    pendingCompression: true,
    trim: trim,
  );

  OutgoingAttachment _copy({
    String? caption,
    Duration? duration,
    Uint8List? poster,
    bool? pendingCompression,
    VideoTrim? trim,
    String? ref,
    DateTime? expires,
  }) => OutgoingAttachment(
    stagedId: stagedId,
    name: name,
    size: size,
    mimeType: mimeType,
    isImage: isImage,
    isVideo: isVideo,
    width: width,
    height: height,
    caption: caption ?? this.caption,
    voice: voice,
    duration: duration ?? this.duration,
    poster: poster ?? this.poster,
    pendingCompression: pendingCompression ?? this.pendingCompression,
    trim: trim ?? this.trim,
    ref: ref ?? this.ref,
    expires: expires ?? this.expires,
  );

  /// The message: the image or video above its caption, the file below
  /// it, or the recording. Its entity carries [ref] once uploaded.
  DraftyContent get content => DraftyContent(switch (voice) {
    final voice? => Drafty.audio(
      DraftyAudio(
        mimeType: mimeType,
        name: name,
        size: size,
        ref: ref,
        duration: voice.duration,
        preview: voice.waveform.isEmpty
            ? null
            : Uint8List.fromList(voice.waveform),
      ),
    ),
    _ when isVideo => Drafty.video(
      DraftyVideo(
        mimeType: mimeType,
        name: name,
        size: size,
        ref: ref,
        width: width,
        height: height,
        duration: duration,
        preview: poster,
        previewMimeType: poster == null ? null : posterMimeType,
      ),
      caption: caption,
    ),
    _ when isImage => Drafty.image(
      DraftyImage(
        mimeType: mimeType,
        name: name,
        size: size,
        ref: ref,
        width: width,
        height: height,
      ),
      caption: caption,
    ),
    _ => Drafty.file(
      DraftyFile(mimeType: mimeType, name: name, size: size, ref: ref),
      caption: caption,
    ),
  });

  Json toJson() => {
    'staged': stagedId,
    'name': name,
    'size': size,
    'mime': ?mimeType,
    if (isImage) 'image': true,
    if (isVideo) 'video': true,
    'width': ?width,
    'height': ?height,
    if (caption.isNotEmpty) 'caption': caption,
    'duration': ?voice?.duration.inMilliseconds,
    if (voice case final voice? when voice.waveform.isNotEmpty)
      'waveform': voice.waveform,
    'videoMs': ?duration?.inMilliseconds,
    if (poster case final poster?) 'poster': base64.encode(poster),
    if (pendingCompression) 'raw': true,
    'trimStart': ?trim?.start.inMilliseconds,
    'trimEnd': ?trim?.end.inMilliseconds,
    'ref': ?ref,
    'expires': ?expires?.toUtc().toIso8601String(),
  };

  static Uint8List? _decode(String data) {
    try {
      return base64.decode(data);
    } on FormatException {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    stagedId,
    name,
    size,
    mimeType,
    isImage,
    isVideo,
    width,
    height,
    caption,
    voice,
    duration,
    poster,
    pendingCompression,
    trim,
    ref,
    expires,
  ];
}
