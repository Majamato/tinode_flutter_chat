import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What the call search shows: the calls of the history whose chat's name
/// matches what the user typed.
///
/// Compares by value, so a change that keeps the same calls in the same
/// order changes nothing.
final class CallMatches with ValueObject {
  const CallMatches([this.ids = const []]);

  /// The [calls] whose chat's name in [titles] (its topic when it has
  /// none) matches [input], exact matches first, each kept in the order of
  /// [calls]; see [matchName].
  factory CallMatches.matching(
    List<CallId> calls,
    Map<String, String> titles,
    String input,
  ) {
    final exact = <CallId>[];
    final typos = <CallId>[];
    for (final call in calls) {
      switch (matchName(titles[call.topic] ?? call.topic, input)) {
        case NameMatch.exact:
          exact.add(call);
        case NameMatch.typo:
          typos.add(call);
        case NameMatch.none:
      }
    }
    return CallMatches(List.unmodifiable([...exact, ...typos]));
  }

  /// The calls shown, best first.
  final List<CallId> ids;

  bool get isEmpty => ids.isEmpty;

  @override
  List<Object?> get props => [ids];
}
