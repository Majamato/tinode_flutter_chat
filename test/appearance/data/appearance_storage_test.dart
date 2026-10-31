import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/appearance/data/appearance_storage.dart';
import 'package:tinode_flutter_chat/src/appearance/domain/stored_appearance.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('appearance_test');
  });

  tearDown(() => directory.delete(recursive: true));

  FileAppearanceStorage storage() =>
      FileAppearanceStorage(directory: () async => directory);

  test('nothing saved reads as the defaults', () async {
    expect(await storage().read(), const StoredAppearance());
  });

  test('reads back what it wrote, the last write winning', () async {
    final writer = storage();
    await Future.wait([
      writer.write(const StoredAppearance(paletteId: 'plum')),
      writer.write(
        const StoredAppearance(paletteId: 'lime', mode: AppearanceMode.dark),
      ),
    ]);

    expect(
      await storage().read(),
      const StoredAppearance(paletteId: 'lime', mode: AppearanceMode.dark),
    );
  });

  test('a broken file reads as the defaults', () async {
    File('${directory.path}/tinode_appearance.json').writeAsStringSync('{');

    expect(await storage().read(), const StoredAppearance());
  });

  test('unknown values keep their defaults', () {
    expect(
      StoredAppearance.fromJson(const {'palette': 3, 'mode': 'sepia'}),
      const StoredAppearance(),
    );
  });
}
