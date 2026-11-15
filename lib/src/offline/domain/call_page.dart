import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Where a call sits in the call log's order, newest first: its time in ms
/// since the epoch, then its chat, then its seq, each descending.
typedef CallKey = ({int time, String topic, int seq});

/// Calls of the call log, newest first, and where the next page starts.
final class CallPage with ValueObject {
  const CallPage(this.calls, {this.next});

  final List<CachedCall> calls;

  /// The key of the last call this page read, readable or not, to read
  /// the next page before; null when nothing older is left. It comes from
  /// the row rather than from [calls], so a page of rows that can't be read
  /// still moves on.
  final CallKey? next;

  /// Nothing older is left.
  bool get reachedEnd => next == null;

  @override
  List<Object?> get props => [calls, next];
}
