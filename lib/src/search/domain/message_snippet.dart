import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Marks where a match starts in the text the cache hands back.
const snippetMatchStart = '\u0002';

/// Marks where a match ends.
const snippetMatchEnd = '\u0003';

/// The part of a found message around what matched, with the matches
/// marked, so the result can show them.
final class MessageSnippet with ValueObject {
  const MessageSnippet(this.parts);

  /// Reads a snippet whose matches sit between [snippetMatchStart] and
  /// [snippetMatchEnd]. A marker without its pair is dropped.
  factory MessageSnippet.parse(String marked) {
    final parts = <SnippetPart>[];
    var match = false;
    final text = StringBuffer();
    void flush() {
      if (text.isNotEmpty) {
        parts.add(SnippetPart(text.toString(), match: match));
        text.clear();
      }
    }

    for (final char in marked.split('')) {
      if (char == snippetMatchStart || char == snippetMatchEnd) {
        flush();
        match = char == snippetMatchStart;
      } else {
        text.write(char);
      }
    }
    flush();
    return MessageSnippet(List.unmodifiable(parts));
  }

  final List<SnippetPart> parts;

  /// The text without the marks.
  String get text => parts.map((p) => p.text).join();

  @override
  List<Object?> get props => [parts];
}

/// A piece of a [MessageSnippet]: matched or not.
final class SnippetPart with ValueObject {
  const SnippetPart(this.text, {this.match = false});

  final String text;
  final bool match;

  @override
  List<Object?> get props => [text, match];
}
