import 'dart:typed_data';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';

/// An image, video, file or recording in a received message. It comes either
/// inline ([bytes]) or as a [ref] to download.
sealed class MessageAttachment with ValueObject {
  const MessageAttachment({
    this.ref,
    this.bytes,
    this.name,
    this.size,
    this.mimeType,
  });

  /// The message's images, then its videos, then its files and
  /// recordings (`AU`), in the order their spans give. Audio sent as a file
  /// (`EX`) stays a file.
  static List<MessageAttachment> listFrom(MessageContent content) =>
      switch (content) {
        DraftyContent(:final drafty) => [
          for (final image in drafty.images)
            if (_usable(image)) ImageAttachment.from(image),
          for (final video in drafty.videos)
            if (_usable(video)) VideoAttachment.from(video),
          for (final file in drafty.files)
            if (_usable(file))
              switch (file) {
                final DraftyAudio audio => VoiceAttachment.from(audio),
                _ => FileAttachment.from(file),
              },
        ],
        _ => const [],
      };

  final String? ref;
  final Uint8List? bytes;
  final String? name;

  /// The size in bytes, as the sender gave it.
  final int? size;
  final String? mimeType;

  /// Something to show: inline bytes or a ref.
  static bool _usable(DraftyFile file) =>
      file.ref != null || file.bytes != null;
}

/// Width over height of an image of [width] by [height] pixels, or
/// [ImageAttachment.defaultAspectRatio] when either is unknown.
double imageAspectRatio(int? width, int? height) => switch ((width, height)) {
  (final w?, final h?) when w > 0 && h > 0 => w / h,
  _ => ImageAttachment.defaultAspectRatio,
};

/// An image shown in the bubble. [width] and [height], in pixels, keep its
/// space while it loads.
final class ImageAttachment extends MessageAttachment {
  const ImageAttachment({
    super.ref,
    super.bytes,
    super.name,
    super.size,
    super.mimeType,
    this.width,
    this.height,
  });

  factory ImageAttachment.from(DraftyImage image) => ImageAttachment(
    ref: image.ref,
    bytes: image.bytes,
    name: image.name,
    size: image.size,
    mimeType: image.mimeType,
    width: image.width,
    height: image.height,
  );

  /// The ratio a bubble keeps before the image arrives, when the sender
  /// gave no size.
  static const double defaultAspectRatio = 4 / 3;

  final int? width;
  final int? height;

  /// Width over height; [defaultAspectRatio] when unknown.
  double get aspectRatio => imageAspectRatio(width, height);

  @override
  List<Object?> get props => [ref, bytes, name, size, mimeType, width, height];
}

/// A video shown as its [poster] with a play button, in the space its size
/// asks for; it downloads and plays full screen.
final class VideoAttachment extends MessageAttachment {
  const VideoAttachment({
    super.ref,
    super.bytes,
    super.name,
    super.size,
    super.mimeType,
    this.width,
    this.height,
    this.duration,
    this.poster,
  });

  factory VideoAttachment.from(DraftyVideo video) => VideoAttachment(
    ref: video.ref,
    bytes: video.bytes,
    name: video.name,
    size: video.size,
    mimeType: video.mimeType,
    width: video.width,
    height: video.height,
    duration: video.duration,
    poster: video.preview,
  );

  final int? width;
  final int? height;

  /// How long it plays, as the sender gave it.
  final Duration? duration;

  /// A still of it, sent inline; null when the sender gave none.
  final Uint8List? poster;

  /// Width over height; `ImageAttachment.defaultAspectRatio` when unknown.
  double get aspectRatio => imageAspectRatio(width, height);

  @override
  List<Object?> get props => [
    ref,
    bytes,
    name,
    size,
    mimeType,
    width,
    height,
    duration,
    poster,
  ];
}

/// A file shown as its name and size, to download and open.
final class FileAttachment extends MessageAttachment {
  const FileAttachment({
    super.ref,
    super.bytes,
    super.name,
    super.size,
    super.mimeType,
  });

  factory FileAttachment.from(DraftyFile file) => FileAttachment(
    ref: file.ref,
    bytes: file.bytes,
    name: file.name,
    size: file.size,
    mimeType: file.mimeType,
  );

  @override
  List<Object?> get props => [ref, bytes, name, size, mimeType];
}

/// A voice message's recording, played in the bubble.
final class VoiceAttachment extends MessageAttachment {
  const VoiceAttachment({
    super.ref,
    super.bytes,
    super.name,
    super.size,
    super.mimeType,
    this.duration,
    this.waveform = const [],
  });

  factory VoiceAttachment.from(DraftyAudio audio) => VoiceAttachment(
    ref: audio.ref,
    bytes: audio.bytes,
    name: audio.name,
    size: audio.size,
    mimeType: audio.mimeType,
    duration: audio.duration,
    waveform: [for (final w in audio.preview ?? const <int>[]) w.clamp(0, 100)],
  );

  /// How long it plays, as the sender gave it.
  final Duration? duration;

  /// The loudness along it, each 0..100; empty when the sender gave none.
  final List<int> waveform;

  /// What the bubble draws: the duration (zero when unknown) and waveform.
  VoiceNote get note =>
      VoiceNote(duration: duration ?? Duration.zero, waveform: waveform);

  /// Where to play it from: the upload, else the bytes in the message
  /// [id] (e.g. its topic and seq); null with neither.
  VoiceSource? sourceIn(String id) => switch ((ref, bytes)) {
    (final ref?, _) => RefVoiceSource(ref),
    (_, final bytes?) => InlineVoiceSource(
      id: id,
      bytes: bytes,
      mimeType: mimeType,
    ),
    _ => null,
  };

  @override
  List<Object?> get props => [
    ref,
    bytes,
    name,
    size,
    mimeType,
    duration,
    waveform,
  ];
}
