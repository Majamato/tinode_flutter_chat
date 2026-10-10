import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// Files kept in memory: for tests, and when the device's folders can't
/// be used.
final class MemoryFileStore implements FileStore {
  final _cache = <String, Uint8List>{};
  final _staged = <String, Uint8List>{};
  var _nextId = 0;

  @override
  Future<LocalFile?> cached(Uri url) async => switch (_cache['$url']) {
    final bytes? => LocalFile.inMemory(bytes),
    null => null,
  };

  @override
  Future<LocalFile> cache(Uri url, Stream<List<int>> bytes) async =>
      LocalFile.inMemory(_cache['$url'] = await _collect(bytes));

  @override
  Future<String> stage(String name, Stream<List<int>> bytes) async {
    final id = '${++_nextId}_$name';
    _staged[id] = await _collect(bytes);
    return id;
  }

  @override
  Future<LocalFile?> staged(String id) async => switch (_staged[id]) {
    final bytes? => LocalFile.inMemory(bytes),
    null => null,
  };

  @override
  Future<void> adopt(String id, Uri url) async {
    if (_staged.remove(id) case final bytes?) {
      _cache['$url'] = bytes;
    }
  }

  @override
  Future<void> unstage(String id) async => _staged.remove(id);

  @override
  Stream<List<int>> read(LocalFile file) => switch (file.bytes) {
    final bytes? => Stream.value(bytes),
    null => Stream.error(StateError('${file.path} is not in memory')),
  };

  /// Whether [url] is cached, for tests.
  bool isCached(Uri url) => _cache.containsKey('$url');

  /// The staged IDs, for tests.
  Iterable<String> get stagedIds => _staged.keys;

  static Future<Uint8List> _collect(Stream<List<int>> bytes) async {
    final builder = BytesBuilder(copy: false);
    await bytes.forEach(builder.add);
    return builder.takeBytes();
  }
}

/// Stores kept in memory for as long as the opener lives.
final class MemoryFileStoreOpener implements FileStoreOpener {
  final stores = <String, MemoryFileStore>{};

  @override
  Future<FileStore> open(Uri server, String userId) async =>
      stores.putIfAbsent('$server $userId', MemoryFileStore.new);

  @override
  Future<void> delete(Uri server, String userId) async =>
      stores.remove('$server $userId');
}
