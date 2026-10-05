import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layer rules of docs/architecture.md on `lib/src`.
void main() {
  final files = Directory('lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList();

  Iterable<String> importsOf(File file) => file
      .readAsLinesSync()
      .where((line) => line.startsWith('import '))
      .map((line) => line.split("'")[1]);

  String? layerOf(String path) => const [
    'domain',
    'data',
    'application',
    'presentation',
  ].where((layer) => path.contains('/$layer/')).firstOrNull;

  const flutter = ['package:flutter/', 'dart:ui', 'package:flutter_riverpod/'];
  const riverpod = ['package:riverpod/', 'package:riverpod_annotation/'];

  final forbidden = <String, List<String>>{
    'domain': [
      ...flutter,
      ...riverpod,
      '/data/',
      '/application/',
      '/presentation/',
    ],
    'data': [...flutter, ...riverpod, '/application/', '/presentation/'],
    'application': [...flutter, '/presentation/'],
    // The composition root in lib/src/app may wire the data layer in.
    'presentation': ['/data/'],
  };

  test('every file sits in a layer', () {
    expect(
      files.where((f) => layerOf(f.path) == null).map((f) => f.path),
      isEmpty,
    );
  });

  test('layers import only what they may', () {
    final violations = [
      for (final file in files)
        for (final import in importsOf(file))
          if (forbidden[layerOf(file.path)]!.any(import.contains) &&
              !(file.path.startsWith('lib/src/app/') &&
                  import.contains('/data/')))
            '${file.path} imports $import',
    ];
    expect(violations, isEmpty);
  });
}
