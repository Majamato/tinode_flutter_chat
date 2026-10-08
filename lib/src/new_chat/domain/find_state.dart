import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// Where a search stands.
enum FindStatus {
  /// Nothing to search yet: the input is too short.
  idle,
  searching,
  done,
  failed,
}

/// A search for people and groups: the latest results, and whether newer
/// ones are on their way.
///
/// Updates return `this` when nothing changed, and keep the same
/// [results] instance while their content is the same.
@immutable
final class FindState {
  const FindState.idle()
    : status = FindStatus.idle,
      results = const [],
      failure = null;

  const FindState._(this.status, this.results, this.failure);

  final FindStatus status;

  /// The latest results, kept while a newer search runs.
  final List<SearchResult> results;

  /// Why the search failed; set when [status] is [FindStatus.failed].
  final ChatFailure? failure;

  FindState searching() => status == FindStatus.searching
      ? this
      : FindState._(FindStatus.searching, results, null);

  FindState done(List<SearchResult> found) => FindState._(
    FindStatus.done,
    const ListEquality<SearchResult>().equals(found, results)
        ? results
        : List.unmodifiable(found),
    null,
  );

  FindState failed(ChatFailure failure) =>
      FindState._(FindStatus.failed, results, failure);
}
