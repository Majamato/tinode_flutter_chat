import 'dart:typed_data';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// An image or file in a received message. It comes either inline
/// ([bytes]) or as a [ref] to download.
sealed class MessageAttachment with ValueObject {
  const MessageAttachment({
    this.ref,
    this.bytes,
    this.name,
    this.size,
    this.mimeType,
  });

  /// The message's images, then its files (audio and video among them), in
  /// the order their spans give.
  static List<MessageAttachment> listFrom(MessageContent content) =>
      switch (content) {
        DraftyContent(:final drafty) => [
          for (final image in drafty.images)
            if (_usable(image)) ImageAttachment.from(image),
          for (final file in drafty.files)
            if (_usable(file)) FileAttachment.from(file),
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
