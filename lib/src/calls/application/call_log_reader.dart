import 'dart:developer';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/domain/call_page.dart';

/// Calls of the call log as entries, and where the next page starts; see
/// `CallPage`.
typedef CallEntries = ({List<CallHistoryEntry> entries, CallKey? next});

/// The calls history's and the call search's way into the call log: a page
/// at a time, as entries, one step after another so that a page and a chat
/// read again never land out of order. Only direct chats have calls.
final class CallLogReader {
  CallLogReader(this._session, this._me);

  final ChatSession _session;

  /// The user, to tell their own calls apart.
  final String _me;

  Future<void> _steps = Future.value();

  /// Runs [step], a read and what follows from it, once the steps queued
  /// before it are done.
  Future<void> queued(Future<void> Function() step) => _steps = _steps
      .then((_) => step())
      .catchError(
        (Object e, StackTrace stackTrace) =>
            _log('A step of the calls failed', e, stackTrace),
      );

  /// The calls `ChatSession.storedCallPage` reads; null when the log can't
  /// be read.
  Future<CallEntries?> read({
    Set<String>? topics,
    CallKey? before,
    CallKey? from,
    int? limit,
  }) async {
    try {
      final page = await _session.storedCallPage(
        topics: topics,
        before: before,
        from: from,
        limit: limit,
      );
      return (
        entries: [
          for (final call in page.calls)
            if (TopicKind.of(call.message.topic) == TopicKind.direct)
              ?CallHistoryEntry.of(call, me: _me),
        ],
        next: page.next,
      );
    } on Object catch (e, stackTrace) {
      _log('Could not read the calls', e, stackTrace);
      return null;
    }
  }

  /// The chats the log has calls of; null when it can't say.
  Future<Set<String>?> topics() async {
    try {
      return await _session.storedCallTopics();
    } on Object catch (e, stackTrace) {
      _log('Could not read the chats with calls', e, stackTrace);
      return null;
    }
  }

  static void _log(String message, Object e, StackTrace stackTrace) => log(
    message,
    name: 'tinode_flutter_chat',
    error: e,
    stackTrace: stackTrace,
  );
}
