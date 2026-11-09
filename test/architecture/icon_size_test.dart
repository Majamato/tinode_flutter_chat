import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Icons take their size from `ChatIconSize`, not a number (docs/widgets.md).
void main() {
  final files = Directory('lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList();

  final constructor = RegExp(r'(?<![A-Za-z_])(Icon|IconThemeData)\(');
  final size = RegExp(r'\bsize:\s*[\d.]');
  final iconSize = RegExp(r'\biconSize:\s*[\d.]');

  /// Everything up to the bracket closing the one just before [start].
  String argumentsFrom(String source, int start) {
    var depth = 1;
    var end = start;
    while (depth > 0 && end < source.length) {
      final char = source[end];
      if ('([{'.contains(char)) {
        depth++;
      } else if (')]}'.contains(char)) {
        depth--;
      }
      end++;
    }
    return source.substring(start, end);
  }

  test('no icon has a numeric size', () {
    final offenders = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      String at(int offset) {
        final line = '\n'.allMatches(source.substring(0, offset)).length + 1;
        return '${file.path}:$line';
      }

      for (final match in constructor.allMatches(source)) {
        if (size.hasMatch(argumentsFrom(source, match.end))) {
          offenders.add(at(match.start));
        }
      }
      for (final match in iconSize.allMatches(source)) {
        offenders.add(at(match.start));
      }
    }

    expect(offenders, isEmpty, reason: 'Use ChatIconSize instead.');
  });
}
