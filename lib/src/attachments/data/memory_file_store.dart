import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// Files kept in memory: for tests, and when the device's folders can't
/// be used.
final class MemoryFileStore implements FileStore {
  /// Used longest ago first: a map keeps its insertion order.
  final _cache = <String, Uint8List>{};
  final _staged = <String, Uint8List>{};
  final _stagedAt = <String, DateTime>{};
  var _nextId = 0;

  @override
  Future<LocalFile?> cached(Uri url) async {
    final bytes = _cache.remove('$url');
    if (bytes == null) {
      return null;
    }
    _cache['$url'] = bytes;
    return LocalFile.inMemory(bytes);
  }

  @override
  Future<LocalFile> cache(Uri url, Stream<List<int>> bytes) async {
    final collected = await _collect(bytes);
    _cache.remove('$url');
    return LocalFile.inMemory(_cache['$url'] = collected);
  }

  @override
  Future<String> stage(String name, Stream<List<int>> bytes) async {
    final id = '${++_nextId}_$name';
    _staged[id] = await _collect(bytes);
    _stagedAt[id] = clock.now();
    return id;
  }

  @override
  Future<LocalFile?> staged(String id) async => switch (_staged[id]) {
    final bytes? => LocalFile.inMemory(bytes),
    null => null,
  };

  @override
  Future<void> adopt(String id, Uri url) async {
    _stagedAt.remove(id);
    if (_staged.remove(id) case final bytes?) {
      _cache
        ..remove('$url')
        ..['$url'] = bytes;
    }
  }

  @override
  Future<void> unstage(String id) async {
    _staged.remove(id);
    _stagedAt.remove(id);
  }

  @override
  Future<void> prune({
    required int maxCacheBytes,
    required Set<String> keepStaged,
  }) async {
    var total = _cache.values.fold(0, (sum, bytes) => sum + bytes.length);
    while (total > maxCacheBytes && _cache.isNotEmpty) {
      total -= _cache.remove(_cache.keys.first)!.length;
    }
    final before = clock.now().subtract(stagedGrace);
    for (final id in [..._staged.keys]) {
      if (!keepStaged.contains(id) && _stagedAt[id]!.isBefore(before)) {
        await unstage(id);
      }
    }
  }

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
