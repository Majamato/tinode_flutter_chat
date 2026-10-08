import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_query.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'find_controller.g.dart';

/// How long the input must stay unchanged before it is searched.
const findDebounce = Duration(milliseconds: 300);

/// Where a search is shown. Each keeps its own, so the member search of a
/// new group doesn't change the search below it.
enum FindScope {
  /// People and groups to open a chat with.
  newChat,

  /// People to add to a new group; groups are left out.
  groupMembers,
}

/// A search for people and groups as the user types: it waits for the
/// input to settle, asks the server and drops answers to older input. The
/// user's own account is left out.
///
/// Searching needs the server: offline it fails, and a failed search runs
/// again once the link is back.
@riverpod
class FindController extends _$FindController {
  late BuildLifetime _lifetime;
  Timer? _debounce;
  String? _query;

  /// Counts the searches; an answer counts only for the latest.
  var _runs = 0;

  @override
  FindState build(FindScope scope) {
    _lifetime = BuildLifetime(ref);
    _query = null;
    final session = ref.watch(activeSessionProvider);
    final reconnects = session?.statusChanges
        .where((s) => s is Connected)
        .listen((_) {
          if (state.status == FindStatus.failed) {
            unawaited(_run());
          }
        });
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(reconnects?.cancel());
    });
    return const FindState.idle();
  }

  /// The user typed [input]: searches it once it stays unchanged for
  /// [findDebounce]. Input too short to search clears the results.
  void search(String input) {
    final query = findQuery(input);
    if (query == _query) {
      return;
    }
    _query = query;
    _debounce?.cancel();
    // An answer to the previous input no longer counts.
    _runs++;
    if (query == null) {
      state = const FindState.idle();
      return;
    }
    state = state.searching();
    _debounce = Timer(findDebounce, () => unawaited(_run()));
  }

  /// Searches the current input again at once, e.g. after a failure.
  void retry() {
    _debounce?.cancel();
    unawaited(_run());
  }

  Future<void> _run() async {
    final query = _query;
    if (query == null) {
      return;
    }
    final run = ++_runs;
    final lifetime = _lifetime;
    bool isCurrent() => lifetime.isActive && run == _runs;
    state = state.searching();
    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      final me = ref.read(currentUserIdProvider);
      final found = await session.find(query);
      if (!isCurrent()) {
        return;
      }
      state = state.done([
        for (final topic in found)
          if (topic.topic != me &&
              (scope == FindScope.newChat || topic.kind == TopicKind.direct))
            SearchResult.fromFound(topic),
      ]);
    } on Object catch (e) {
      if (isCurrent()) {
        state = state.failed(ChatFailure.of(e));
      }
    }
  }
}
