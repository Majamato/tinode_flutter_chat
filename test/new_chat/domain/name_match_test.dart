import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';

void main() {
  test('every typed word starts a word of the name', () {
    expect(nameMatches('Mario Martínez', 'ma mar'), isTrue);
    expect(nameMatches('Mario Martínez', 'mart'), isTrue);
    expect(nameMatches('Mario Martínez', 'ario'), isFalse);
    expect(nameMatches('Mario Martínez', 'mario x'), isFalse);
  });

  test('case and accents do not count', () {
    expect(nameMatches('José Núñez', 'JOSE nunez'), isTrue);
    expect(nameMatches('Jose', 'josé'), isTrue);
    expect(nameMatches('Françoise', 'franc'), isTrue);
  });

  test('blank input matches everyone', () {
    expect(nameMatches('Bob', ''), isTrue);
    expect(nameMatches('Bob', '  , '), isTrue);
  });

  test('punctuation separates words', () {
    expect(nameMatches('~Mario (work)', 'work'), isTrue);
  });
}
