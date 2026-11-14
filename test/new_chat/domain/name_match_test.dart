import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';

void main() {
  test('every typed word starts a word of the name', () {
    expect(matchName('Mario Martínez', 'ma mar'), NameMatch.exact);
    expect(matchName('Mario Martínez', 'mart'), NameMatch.exact);
    expect(matchName('Alice', 'ali'), NameMatch.exact);
    expect(matchName('Mario Martínez', 'rio'), NameMatch.none);
    expect(matchName('Mario Martínez', 'mario x'), NameMatch.none);
  });

  test('case and accents do not count', () {
    expect(matchName('José Núñez', 'JOSE nunez'), NameMatch.exact);
    expect(matchName('Jose', 'josé'), NameMatch.exact);
    expect(matchName('Françoise', 'franc'), NameMatch.exact);
  });

  test('blank input matches everyone', () {
    expect(matchName('Bob', ''), NameMatch.exact);
    expect(matchName('Bob', '  , '), NameMatch.exact);
  });

  test('punctuation separates words', () {
    expect(matchName('~Mario (work)', 'work'), NameMatch.exact);
  });

  test('a typed word may miss a letter', () {
    expect(matchName('Alice', 'alce'), NameMatch.typo);
    expect(matchName('Alice', 'lice'), NameMatch.typo);
    expect(matchName('Mario Martínez', 'mario matin'), NameMatch.typo);
  });

  test('a typed word may have an extra, wrong or swapped letter', () {
    expect(matchName('Alice', 'allice'), NameMatch.typo);
    expect(matchName('Alice', 'alise'), NameMatch.typo);
    expect(matchName('Alice', 'laice'), NameMatch.typo);
    expect(matchName('Bob', 'bobb'), NameMatch.typo);
  });

  test('two letters off is no match', () {
    expect(matchName('Alice', 'axxce'), NameMatch.none);
    expect(matchName('Alice', 'aice x'), NameMatch.none);
  });

  test('short words must be exact', () {
    expect(matchName('Bob', 'bx'), NameMatch.none);
    expect(matchName('Bob', 'ob'), NameMatch.none);
  });
}
