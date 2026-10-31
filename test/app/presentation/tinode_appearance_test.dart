import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/appearance/data/appearance_storage.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/test_palettes.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('appearance_test');
  });

  tearDown(() => directory.delete(recursive: true));

  Future<TinodeAppearance> load() => TinodeAppearance.loadFrom(
    FileAppearanceStorage(directory: () async => directory),
    palettes: [slate, plum],
  );

  test('starts with the first palette, as the device is', () async {
    final appearance = await load();

    expect(appearance.palette, slate);
    expect(appearance.defaultPalette, slate);
    expect(appearance.themeMode, ThemeMode.system);
  });

  test('remembers the choice for the next start', () async {
    final appearance = await load();
    var notified = 0;
    appearance
      ..addListener(() => notified++)
      ..selectPalette('plum')
      ..selectThemeMode(ThemeMode.dark)
      ..selectPalette('plum');
    await appearance.saved;

    expect(notified, 2);
    final again = await load();
    expect(again.palette, plum);
    expect(again.themeMode, ThemeMode.dark);
  });

  test('reset goes back to the default palette, not the theme', () async {
    final appearance = TinodeAppearance.inMemory(
      palettes: [slate, plum],
      paletteId: 'plum',
      themeMode: ThemeMode.light,
    )..resetPalette();

    expect(appearance.palette, slate);
    expect(appearance.themeMode, ThemeMode.light);
  });

  test('an unknown palette falls back to the default', () {
    final appearance = TinodeAppearance.inMemory(
      palettes: [slate, plum],
      paletteId: 'gone',
    )..selectPalette('nope');

    expect(appearance.palette, slate);
  });
}
