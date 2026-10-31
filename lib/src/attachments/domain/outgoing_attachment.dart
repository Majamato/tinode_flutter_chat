import 'dart:typed_data';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';

/// The image, file or recording of a message in the outbox: the staged
/// copy to upload, what the message says about it, and, once uploaded, its
/// [ref] and when that [expires].
final class OutgoingAttachment with ValueObject {
  const OutgoingAttachment({
    required this.stagedId,
    required this.name,
    required this.size,
    this.mimeType,
    this.isImage = false,
    this.width,
    this.height,
    this.caption = '',
    this.voice,
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
      ref: get('ref'),
      expires: switch (get<String>('expires')) {
        final time? => DateTime.tryParse(time),
        null => null,
      },
    );
  }

  /// A ref this close to expiring is uploaded again rather than sent.
  static const expiryMargin = Duration(seconds: 5);

  /// The staged copy, see `FileStore.stage`.
  final String stagedId;
  final String name;

  /// The size in bytes.
  final int size;
  final String? mimeType;
  final bool isImage;

  /// The image's size in pixels, when known.
  final int? width;
  final int? height;
  final String caption;

  /// Set for a voice message, sent as a recording rather than a file.
  final VoiceNote? voice;
  final String? ref;
  final DateTime? expires;

  /// Width over height, for an image's bubble.
  double get aspectRatio => imageAspectRatio(width, height);

  /// Whether it must be uploaded (again) before the message can go.
  bool needsUpload(DateTime now) =>
      ref == null ||
      (expires != null && !expires!.isAfter(now.add(expiryMargin)));

  OutgoingAttachment uploaded(String ref, DateTime expires) =>
      OutgoingAttachment(
        stagedId: stagedId,
        name: name,
        size: size,
        mimeType: mimeType,
        isImage: isImage,
        width: width,
        height: height,
        caption: caption,
        voice: voice,
        ref: ref,
        expires: expires,
      );

  /// The message: the image above its caption, the file below it, or the
  /// recording. Its entity carries [ref] once uploaded.
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
    'width': ?width,
    'height': ?height,
    if (caption.isNotEmpty) 'caption': caption,
    'duration': ?voice?.duration.inMilliseconds,
    if (voice case final voice? when voice.waveform.isNotEmpty)
      'waveform': voice.waveform,
    'ref': ?ref,
    'expires': ?expires?.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    stagedId,
    name,
    size,
    mimeType,
    isImage,
    width,
    height,
    caption,
    voice,
    ref,
    expires,
  ];
}
