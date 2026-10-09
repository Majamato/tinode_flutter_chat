import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';

/// A profile photo sent inline (`photo.data`), decoded once.
///
/// Equal photos share their [bytes], so an image widget built on them
/// keeps its decoded picture when a profile is read again. A photo given
/// only by reference (`photo.ref`) needs an authenticated download, which
/// comes with attachments; until then it is no [AvatarImage].
@immutable
final class AvatarImage {
  const AvatarImage._(this._data, this.bytes);

  /// Null when [photo] has no inline data, or data that isn't base64.
  static AvatarImage? tryParse(ProfilePhoto? photo) {
    final data = photo?.data;
    if (data == null || data.isEmpty) {
      return null;
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
    return _decoded[data] = AvatarImage._(data, bytes);
  }

  /// How many decoded photos are kept for reuse.
  static const _cacheSize = 256;
  static final _decoded = <String, AvatarImage>{};

  final String _data;

  /// The encoded image, e.g. a JPEG.
  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AvatarImage && other._data == _data;

  @override
  int get hashCode => _data.hashCode;

  @override
  String toString() => 'AvatarImage(${bytes.length} bytes)';
}
