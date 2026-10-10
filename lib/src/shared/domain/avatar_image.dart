import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';

/// A profile photo: sent inline (`photo.data`), decoded once, or given by
/// reference (`photo.ref`) to an upload the avatar downloads.
///
/// Equal inline photos share their [bytes], so an image widget built on
/// them keeps its decoded picture when a profile is read again.
@immutable
final class AvatarImage {
  const AvatarImage._(this._key, {this.bytes, this.ref});

  /// Null when [photo] has neither usable inline data nor a ref. Inline
  /// data wins over a ref.
  static AvatarImage? tryParse(ProfilePhoto? photo) {
    final data = photo?.data;
    if (data == null || data.isEmpty) {
      return switch (photo?.ref) {
        final ref? when ref.isNotEmpty => AvatarImage._('ref $ref', ref: ref),
        _ => null,
      };
    }
    if (_decoded.remove(data) case final known?) {
      // Most recently used goes last.
      return _decoded[data] = known;
    }
    final Uint8List bytes;
    try {
      bytes = base64.decode(base64.normalize(data));
    } on FormatException {
      return null;
    }
    if (_decoded.length >= _cacheSize) {
      _decoded.remove(_decoded.keys.first);
    }
    return _decoded[data] = AvatarImage._(data, bytes: bytes);
  }

  /// How many decoded photos are kept for reuse.
  static const _cacheSize = 256;
  static final _decoded = <String, AvatarImage>{};

  final String _key;

  /// The encoded image, e.g. a JPEG, when sent inline.
  final Uint8List? bytes;

  /// The upload to download, when given by reference.
  final String? ref;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AvatarImage && other._key == _key;

  @override
  int get hashCode => _key.hashCode;

  @override
  String toString() => switch (bytes) {
    final bytes? => 'AvatarImage(${bytes.length} bytes)',
    null => 'AvatarImage($ref)',
  };
}
