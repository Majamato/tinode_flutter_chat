import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A file on this device: in the file cache, or staged for sending. It
/// lives at [path] on disk, or, in a cache kept in memory, in [bytes].
final class LocalFile with ValueObject {
  const LocalFile.atPath(String this.path, {required this.length})
    : bytes = null;

  LocalFile.inMemory(Uint8List this.bytes) : path = null, length = bytes.length;

  final String? path;
  final Uint8List? bytes;

  /// The size in bytes.
  final int length;

  @override
  List<Object?> get props => [path, length, if (path == null) bytes];
}
