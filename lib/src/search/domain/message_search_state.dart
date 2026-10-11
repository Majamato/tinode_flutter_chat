import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/search/domain/found_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// Where a message search stands.
enum MessageSearchStatus {
  /// Nothing to search yet: the input is too short.
  idle,
  searching,
  done,
  failed,
}

/// A message search: the found messages so far, newest first, and whether
/// more are on their way.
///
/// Updates return `this` when nothing changed, and keep the same
/// [results] instance while their content is the same.
@immutable
final class MessageSearchState {
  const MessageSearchState.idle()
    : status = MessageSearchStatus.idle,
      results = const [],
      hasMore = false,
      loadingMore = false,
      failure = null;

  const MessageSearchState._({
    required this.status,
    required this.results,
    required this.hasMore,
    required this.loadingMore,
    required this.failure,
  });

  final MessageSearchStatus status;

  /// The latest results, kept while a newer search runs.
  final List<FoundMessage> results;

  /// The cache may hold more results than [results].
  final bool hasMore;
  final bool loadingMore;

  /// Why the search failed; set when [status] is
  /// [MessageSearchStatus.failed].
  final ChatFailure? failure;

  MessageSearchState searching() => status == MessageSearchStatus.searching
      ? this
      : _copy(status: MessageSearchStatus.searching, loadingMore: false);

  /// The first page of a search.
  MessageSearchState done(List<FoundMessage> found, {required bool hasMore}) =>
      _copy(
        status: MessageSearchStatus.done,
        results: const ListEquality<FoundMessage>().equals(found, results)
            ? results
            : List.unmodifiable(found),
        hasMore: hasMore,
        loadingMore: false,
      );

  /// The next page, after [results].
  MessageSearchState withMore(
    List<FoundMessage> more, {
    required bool hasMore,
  }) => _copy(
    results: more.isEmpty ? results : List.unmodifiable([...results, ...more]),
    hasMore: hasMore,
    loadingMore: false,
  );

  MessageSearchState withLoadingMore({required bool loading}) =>
      loading == loadingMore ? this : _copy(loadingMore: loading);

  MessageSearchState failed(ChatFailure failure) => MessageSearchState._(
    status: MessageSearchStatus.failed,
    results: results,
    hasMore: false,
    loadingMore: false,
    failure: failure,
  );

  MessageSearchState _copy({
    MessageSearchStatus? status,
    List<FoundMessage>? results,
    bool? hasMore,
    bool? loadingMore,
  }) => MessageSearchState._(
    status: status ?? this.status,
    results: results ?? this.results,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: null,
  );
}
