import 'package:tinode_dart_client/tinode_dart_client.dart';

/// The seqs that message [seq], with [head], keeps out of the unread count.
///
/// A message that updates another (`head.replace`, e.g. a call's later
/// state) has no bubble of its own, so it doesn't count; and the user
/// already dealt with a call that was answered or declined, so it doesn't
/// count either, whichever device did it. The read marker can't say so: it
/// would take every unread message before the call with it.
Set<int> uncountedBy(int seq, MessageHead? head) => switch (head) {
  MessageHead(:final replacesSeq?, :final callState) => {
    seq,
    if (callState == CallState.accepted ||
        callState == CallState.finished ||
        callState == CallState.declined)
      replacesSeq,
  },
  _ => const {},
};
