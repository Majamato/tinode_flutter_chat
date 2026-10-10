import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show Random;

import 'package:crypto/crypto.dart';

import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';

/// Files in two folders: the cache, which the OS may clear, and staged
/// files, which it keeps until they are sent.
final class IoFileStore implements FileStore {
  IoFileStore(this._cacheDir, this._stagingDir);

  final Directory _cacheDir;
  final Directory _stagingDir;
  final _random = Random();

  @override
  Future<LocalFile?> cached(Uri url) => _existing(_cacheFile(url));

  @override
  Future<LocalFile> cache(Uri url, Stream<List<int>> bytes) async {
    final file = _cacheFile(url);
    await _write(file, bytes);
    return LocalFile.atPath(file.path, length: await file.length());
  }

  @override
  Future<String> stage(String name, Stream<List<int>> bytes) async {
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${_random.nextInt(1 << 32).toRadixString(36)}'
        '${_extension(name)}';
    await _write(File('${_stagingDir.path}/$id'), bytes);
    return id;
  }

  @override
  Future<LocalFile?> staged(String id) => _existing(_stagedFile(id));

  @override
  Future<void> adopt(String id, Uri url) async {
    final staged = _stagedFile(id);
    if (!staged.existsSync()) {
      return;
    }
    final target = _cacheFile(url);
    await target.parent.create(recursive: true);
    try {
      await staged.rename(target.path);
    } on FileSystemException {
      // The folders may sit on different volumes.
      await staged.copy(target.path);
      await staged.delete();
    }
  }

  @override
  Future<void> unstage(String id) async {
    final file = _stagedFile(id);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Stream<List<int>> read(LocalFile file) => switch ((file.path, file.bytes)) {
    (final path?, _) => File(path).openRead(),
    (_, final bytes?) => Stream.value(bytes),
    _ => const Stream.empty(),
  };

  /// A staged ID is a bare file name; anything else is refused.
  File _stagedFile(String id) {
    if (id.contains('/') || id.contains(r'\') || id.startsWith('.')) {
      throw ArgumentError.value(id, 'id', 'is not a staged file');
    }
    return File('${_stagingDir.path}/$id');
  }

  /// Named by a hash of the URL, keeping its extension so the OS knows
  /// the type when the file is opened.
  File _cacheFile(Uri url) => File(
    '${_cacheDir.path}/${sha1.convert(utf8.encode('$url'))}'
    '${_extension(url.path)}',
  );

  static Future<LocalFile?> _existing(File file) async => file.existsSync()
      ? LocalFile.atPath(file.path, length: await file.length())
      : null;

  /// Writes to a side file first, so a broken write leaves nothing.
  static Future<void> _write(File file, Stream<List<int>> bytes) async {
    await file.parent.create(recursive: true);
    final part = File('${file.path}.part');
    try {
      final sink = part.openWrite();
      try {
        await sink.addStream(bytes);
      } finally {
        await sink.close();
      }
      await part.rename(file.path);
    } on Object {
      if (part.existsSync()) {
        await part.delete();
      }
      rethrow;
    }
  }

  /// `.jpg` from `photo.jpg`; empty when there is no short, plain one.
  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot < name.lastIndexOf('/')) {
      return '';
    }
    final extension = name.substring(dot);
    return RegExp(r'^\.[A-Za-z0-9]{1,8}$').hasMatch(extension)
        ? extension.toLowerCase()
        : '';
  }
}

/// One cache and one staging folder per server and user.
final class DeviceFileStoreOpener implements FileStoreOpener {
  @override
  Future<FileStore> open(Uri server, String userId) async {
    final (cache, staging) = await _folders(server, userId);
    await cache.create(recursive: true);
    await staging.create(recursive: true);
    return IoFileStore(cache, staging);
  }

  @override
  Future<void> delete(Uri server, String userId) async {
    final (cache, staging) = await _folders(server, userId);
    for (final folder in [cache, staging]) {
      if (folder.existsSync()) {
        await folder.delete(recursive: true);
      }
    }
  }

  static Future<(Directory, Directory)> _folders(
    Uri server,
    String userId,
  ) async {
    final name = userStorageName(server, userId);
    return (
      Directory('${(await getApplicationCacheDirectory()).path}/${name}_files'),
      Directory(
        '${(await getApplicationSupportDirectory()).path}/${name}_staging',
      ),
    );
  }
}

/// Opens [userId]'s files, or, when that fails, a store in memory so
/// attachments still work for this session.
Future<FileStore> openFilesOrFallBack(
  FileStoreOpener opener,
  Uri server,
  String userId,
) async {
  try {
    return await opener.open(server, userId);
  } on Object catch (e, stackTrace) {
    log(
      'Could not open the file cache; using memory instead',
      name: 'tinode_flutter_chat',
      error: e,
      stackTrace: stackTrace,
    );
    return MemoryFileStore();
  }
}
