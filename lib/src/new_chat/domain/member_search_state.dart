import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/member_suggestions.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The server's search for new group members, without the people the
/// suggestions already show.
final class MemberSearchState with ValueObject {
  const MemberSearchState({
    required this.status,
    this.found = const [],
    this.failure,
  });

  factory MemberSearchState.of(FindState find, MemberSuggestions shown) =>
      MemberSearchState(
        status: find.status,
        failure: find.failure,
        found: List.unmodifiable([
          for (final result in find.results)
            if (!shown.has(result.topic)) result,
        ]),
      );

  final FindStatus status;

  /// What the server found that isn't suggested.
  final List<SearchResult> found;

  /// Why the search failed; set when [status] is [FindStatus.failed].
  final ChatFailure? failure;

  @override
  List<Object?> get props => [status, found, failure];
}
