import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_snippet.dart';

void main() {
  const s = snippetMatchStart;
  const e = snippetMatchEnd;

  test('splits the text at the marks', () {
    final snippet = MessageSnippet.parse('…lunch at ${s}noon$e with ${s}Bob$e');

    expect(snippet.parts, const [
      SnippetPart('…lunch at '),
      SnippetPart('noon', match: true),
      SnippetPart(' with '),
      SnippetPart('Bob', match: true),
    ]);
    expect(snippet.text, '…lunch at noon with Bob');
  });

  test('text without marks is one plain part', () {
    expect(MessageSnippet.parse('hi').parts, const [SnippetPart('hi')]);
    expect(MessageSnippet.parse('').parts, isEmpty);
  });

  test('an unpaired mark is dropped', () {
    expect(MessageSnippet.parse('${s}hi').parts, const [
      SnippetPart('hi', match: true),
    ]);
    expect(MessageSnippet.parse('hi$e there').parts, const [
      SnippetPart('hi'),
      SnippetPart(' there'),
    ]);
  });
}
