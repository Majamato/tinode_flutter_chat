import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Whose calls the call search shows: the chats whose name matches what
/// the user typed, exactly or a letter off.
///
/// Compares by value, so a chat list change that leaves the same chats
/// matching changes nothing.
final class CallMatches with ValueObject {
  const CallMatches({this.exact = const {}, this.typos = const {}});

  /// Every chat matches exactly, as blank input does.
  const CallMatches.everyChat() : exact = null, typos = const {};

  /// Those of [topics] whose name in [titles] (its topic when it has none)
  /// matches [input]; see [matchName].
  factory CallMatches.of(
    Iterable<String> topics,
    Map<String, String> titles,
    String input,
  ) {
    if (matchesEveryone(input)) {
      return const CallMatches.everyChat();
    }
    final exact = <String>{};
    final typos = <String>{};
    for (final topic in topics) {
      switch (matchName(titles[topic] ?? topic, input)) {
        case NameMatch.exact:
          exact.add(topic);
        case NameMatch.typo:
          typos.add(topic);
        case NameMatch.none:
      }
    }
    return CallMatches(
      exact: Set.unmodifiable(exact),
      typos: Set.unmodifiable(typos),
    );
  }

  /// The chats that match exactly; null for every chat.
  final Set<String>? exact;

  /// The chats that match with a letter off, shown after the exact ones.
  final Set<String> typos;

  /// Whether [topic]'s calls are among those shown.
  bool includes(String topic) =>
      (exact?.contains(topic) ?? true) || typos.contains(topic);

  @override
  List<Object?> get props => [exact, typos];
}
