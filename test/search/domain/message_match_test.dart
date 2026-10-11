import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_match.dart';

void main() {
  test('each word must start a word of the message', () {
    expect(messageMatch('hello world'), '"hello"* "world"*');
    expect(messageMatch('  Café, con   leche! '), '"Café"* "con"* "leche"*');
  });

  test('query syntax in the input is only a separator', () {
    expect(messageMatch('"a" OR b*'), '"a"* "OR"* "b"*');
    expect(messageMatch('NEAR(x y)'), '"NEAR"* "x"* "y"*');
    expect(messageMatch("it's"), '"it"* "s"*');
  });

  test('input with fewer than two letters or digits is not searched', () {
    expect(messageMatch(''), isNull);
    expect(messageMatch('a'), isNull);
    expect(messageMatch('!? *'), isNull);
    expect(messageMatch('a b'), '"a"* "b"*');
    expect(messageMatch('42'), '"42"*');
  });

  test('keeps letters of any script, with their marks', () {
    expect(messageMatch('привет'), '"привет"*');
    expect(messageMatch('café'), '"café"*');
  });
}
