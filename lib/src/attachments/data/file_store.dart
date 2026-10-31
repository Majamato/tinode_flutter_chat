import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// How old a staged file that no message refers to must be before pruning
/// deletes it: younger ones may belong to a message being queued.
const stagedGrace = Duration(hours: 1);

/// One user's files on this device: downloads and sent files kept by
/// their URL (the cache, which the OS may clear), files kept the same way
/// but never cleared (voice messages, deleted with their message), and
/// files staged for sending, kept until the server has them.
abstract interface class FileStore {
  /// The file for [url], kept or cached, if any. With [keep], a cached
  /// one moves among the kept files.
  Future<LocalFile?> cached(Uri url, {bool keep = false});

  /// Writes [bytes] to the cache under [url], or with [keep] among the
  /// kept files. A failed or cancelled write leaves nothing behind.
  Future<LocalFile> cache(
    Uri url,
    Stream<List<int>> bytes, {
    bool keep = false,
  });

  /// Copies a file the user picked into the staging area, as picker files
  /// can vanish; returns its staged ID.
  Future<String> stage(String name, Stream<List<int>> bytes);

  /// The staged file [id], null when it is gone.
  Future<LocalFile?> staged(String id);

  /// Moves the staged file [id] into the cache under [url], once sent, or
  /// with [keep] among the kept files.
  Future<void> adopt(String id, Uri url, {bool keep = false});

  /// Deletes the kept file for [url], if there is one.
  Future<void> forget(Uri url);

  /// Deletes the staged file [id], if it is still there.
  Future<void> unstage(String id);

  /// The contents of [file].
  Stream<List<int>> read(LocalFile file);

  /// Frees space: deletes the cached files used longest ago until the rest
  /// take at most [maxCacheBytes], and staged files left behind, e.g. by a
  /// crash: those not in [keepStaged] and older than [stagedGrace]. Kept
  /// files stay.
  Future<void> prune({
    required int maxCacheBytes,
    required Set<String> keepStaged,
  });
}

/// Opens and deletes the per-user [FileStore]s.
abstract interface class FileStoreOpener {
  Future<FileStore> open(Uri server, String userId);

  /// Deletes everything [userId] has on [server]: cached, kept and staged
  /// files.
  Future<void> delete(Uri server, String userId);
}
