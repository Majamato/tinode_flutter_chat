import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/io_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

void main() {
  late Directory root;
  late Directory cacheDir;
  late Directory stagingDir;
  late Directory keptDir;
  late IoFileStore store;
  final now = DateTime(2026, 10, 11, 12);

  setUp(() {
    root = Directory.systemTemp.createTempSync('io_file_store_test');
    addTearDown(() => root.deleteSync(recursive: true));
    cacheDir = Directory('${root.path}/cache')..createSync();
    stagingDir = Directory('${root.path}/staging')..createSync();
    keptDir = Directory('${root.path}/kept')..createSync();
    store = IoFileStore(cacheDir, stagingDir, keptDir);
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

  group('kept files', () {
    bool isIn(Directory dir, LocalFile? file) =>
        file?.path != null && File(file!.path!).parent.path == dir.path;

    test('go in their own folder, and pruning leaves them', () async {
      final kept = await store.cache(
        url('voice.m4a'),
        Stream.value(List.filled(400, 0)),
        keep: true,
      );
      expect(isIn(keptDir, kept), isTrue);
      expect(kept.path, endsWith('.m4a'));

      await withClock(
        Clock.fixed(now),
        () => store.prune(maxCacheBytes: 0, keepStaged: {}),
      );
      expect(await store.cached(url('voice.m4a')), kept);
    });

    test('a sent one moves there from staging', () async {
      final id = await store.stage('voice.m4a', Stream.value([1, 2]));
      await store.adopt(id, url('sent.m4a'), keep: true);

      expect(await store.staged(id), isNull);
      final found = await store.cached(url('sent.m4a'));
      expect(isIn(keptDir, found), isTrue);
      expect(found!.length, 2);
    });

    test('a cached one moves there when asked to keep it', () async {
      await cache('old.m4a', 3, 10);

      final found = await store.cached(url('old.m4a'), keep: true);
      expect(isIn(keptDir, found), isTrue);
      expect(cacheDir.listSync(), isEmpty);
    });

    test('forget deletes one', () async {
      await store.cache(url('voice.m4a'), Stream.value([1]), keep: true);
      await store.forget(url('voice.m4a'));
      await store.forget(url('never.m4a'));

      expect(await store.cached(url('voice.m4a')), isNull);
    });
  });
}
