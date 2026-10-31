import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';

void main() {
  late MemoryFileStore store;

  setUp(() => store = MemoryFileStore());

  Uri url(String name) => Uri.parse('https://chat.example.com/v0/file/s/$name');

  test('kept files outlive pruning, until forgotten', () async {
    await store.cache(url('voice.m4a'), Stream.value([1, 2, 3]), keep: true);
    await store.cache(url('photo.jpg'), Stream.value([4, 5, 6]));

    await store.prune(maxCacheBytes: 0, keepStaged: {});
    expect(store.isKept(url('voice.m4a')), isTrue);
    expect(store.isCached(url('photo.jpg')), isFalse);
    expect((await store.cached(url('voice.m4a')))!.length, 3);

    await store.forget(url('voice.m4a'));
    expect(await store.cached(url('voice.m4a')), isNull);
  });

  test(
    'a sent file is adopted as kept, and a cached one kept on asking',
    () async {
      final id = await store.stage('voice.m4a', Stream.value([1]));
      await store.adopt(id, url('sent.m4a'), keep: true);
      expect(store.isKept(url('sent.m4a')), isTrue);
      expect(store.stagedIds, isEmpty);

      await store.cache(url('old.m4a'), Stream.value([2]));
      await store.cached(url('old.m4a'), keep: true);
      expect(store.isKept(url('old.m4a')), isTrue);
      expect(store.isCached(url('old.m4a')), isFalse);
    },
  );
}
