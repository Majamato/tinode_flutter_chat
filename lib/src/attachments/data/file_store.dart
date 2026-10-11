import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// How old a staged file that no message refers to must be before pruning
/// deletes it: younger ones may belong to a message being queued.
const stagedGrace = Duration(hours: 1);

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

  /// Frees space: deletes the cached files used longest ago until the rest
  /// take at most [maxCacheBytes], and staged files left behind, e.g. by a
  /// crash: those not in [keepStaged] and older than [stagedGrace].
  Future<void> prune({
    required int maxCacheBytes,
    required Set<String> keepStaged,
  });
}

/// Opens and deletes the per-user [FileStore]s.
abstract interface class FileStoreOpener {
  Future<FileStore> open(Uri server, String userId);

  /// Deletes everything [userId] has on [server]: cache and staged files.
  Future<void> delete(Uri server, String userId);
}
