import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One public widget per file (docs/widgets.md); private helpers that only
/// that widget uses may share its file.
void main() {
  final widget = RegExp(
    r'^class ([A-Z]\w*) extends (Stateless|Stateful|Consumer|ConsumerStateful|Inherited)Widget\b',
    multiLine: true,
  );

  test('no file declares two public widgets', () {
    final crowded = <String, List<String>>{
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          file.path: [
            for (final match in widget.allMatches(file.readAsStringSync()))
              match.group(1)!,
          ],
    }..removeWhere((_, widgets) => widgets.length < 2);
    expect(crowded, isEmpty);
  });

  test('presentation files hold no providers', () {
    final providers = [
      for (final file in Directory('lib/src').listSync(recursive: true))
        if (file is File &&
            file.path.contains('/presentation/') &&
            file.readAsStringSync().contains('@riverpod'))
          file.path,
    ];
    expect(providers, isEmpty);
  });
}
