import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/io_file_store.dart';

void main() {
  late Directory root;
  late Directory cacheDir;
  late Directory stagingDir;
  late IoFileStore store;
  final now = DateTime(2026, 10, 11, 12);

  setUp(() {
    root = Directory.systemTemp.createTempSync('io_file_store_test');
    addTearDown(() => root.deleteSync(recursive: true));
    cacheDir = Directory('${root.path}/cache')..createSync();
    stagingDir = Directory('${root.path}/staging')..createSync();
    store = IoFileStore(cacheDir, stagingDir);
  });

  Uri url(String name) => Uri.parse('https://chat.example.com/v0/file/s/$name');

  /// Caches [size] bytes under [name], last used [minutesAgo].
  Future<void> cache(String name, int size, int minutesAgo) async {
    final file = await withClock(
      Clock.fixed(now),
      () => store.cache(url(name), Stream.value(List.filled(size, 0))),
    );
    File(
      file.path!,
    ).setLastModifiedSync(now.subtract(Duration(minutes: minutesAgo)));
  }

  Future<bool> isCached(String name) async =>
      await withClock(Clock.fixed(now), () => store.cached(url(name))) != null;

  test('deletes the files used longest ago until the rest fit', () async {
    await cache('old.jpg', 400, 30);
    await cache('middle.jpg', 400, 20);
    await cache('new.jpg', 400, 10);
    File('${cacheDir.path}/broken.part').writeAsBytesSync([1, 2, 3]);

    await withClock(
      Clock.fixed(now),
      () => store.prune(maxCacheBytes: 900, keepStaged: {}),
    );

    expect(await isCached('old.jpg'), isFalse);
    expect(await isCached('middle.jpg'), isTrue);
    expect(await isCached('new.jpg'), isTrue);
    expect(File('${cacheDir.path}/broken.part').existsSync(), isFalse);
  });

  test('a cache hit counts as a use', () async {
    await cache('a.jpg', 400, 30);
    await cache('b.jpg', 400, 20);
    expect(await isCached('a.jpg'), isTrue);

    await withClock(
      Clock.fixed(now.add(const Duration(minutes: 1))),
      () => store.prune(maxCacheBytes: 500, keepStaged: {}),
    );

    expect(await isCached('a.jpg'), isTrue);
    expect(await isCached('b.jpg'), isFalse);
  });

  test('deletes old staged files no message refers to', () async {
    final kept = await store.stage('kept.jpg', Stream.value([1]));
    final orphan = await store.stage('orphan.jpg', Stream.value([2]));
    final fresh = await store.stage('fresh.jpg', Stream.value([3]));
    final old = now.subtract(stagedGrace * 2);
    for (final id in [kept, orphan]) {
      File('${stagingDir.path}/$id').setLastModifiedSync(old);
    }
    File('${stagingDir.path}/$fresh').setLastModifiedSync(now);

    await withClock(
      Clock.fixed(now),
      () => store.prune(maxCacheBytes: 1 << 20, keepStaged: {kept}),
    );

    expect(await store.staged(kept), isNotNull);
    expect(await store.staged(orphan), isNull);
    expect(await store.staged(fresh), isNotNull);
  });
}
