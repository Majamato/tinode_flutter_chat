import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// One user's files on this device: downloads and sent files kept by
/// their URL (the cache, which the OS may clear), and files staged for
/// sending, kept until the server has them.
abstract interface class FileStore {
  /// The cached file for [url], if any.
  Future<LocalFile?> cached(Uri url);

  /// Writes [bytes] to the cache under [url]. A failed or cancelled write
  /// leaves nothing behind.
  Future<LocalFile> cache(Uri url, Stream<List<int>> bytes);

  /// Copies a file the user picked into the staging area, as picker files
  /// can vanish; returns its staged ID.
  Future<String> stage(String name, Stream<List<int>> bytes);

  /// The staged file [id], null when it is gone.
  Future<LocalFile?> staged(String id);

  /// Moves the staged file [id] into the cache under [url], once sent.
  Future<void> adopt(String id, Uri url);

  /// Deletes the staged file [id], if it is still there.
  Future<void> unstage(String id);

  /// The contents of [file].
  Stream<List<int>> read(LocalFile file);
}

/// Opens and deletes the per-user [FileStore]s.
abstract interface class FileStoreOpener {
  Future<FileStore> open(Uri server, String userId);

  /// Deletes everything [userId] has on [server]: cache and staged files.
  Future<void> delete(Uri server, String userId);
}
