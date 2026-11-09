import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';

part 'sent_stand_ins.g.dart';

/// What the outgoing bubbles of photos and videos last showed (a poster
/// or the staged copy), by their message's client ID. The sent message
/// carries the same ID, whether the server's echo or its ack came first,
/// so its bubble finds the picture at once and shows it until its own is
/// ready: the picture never blinks out. Keeps the latest [capacity] only.
final class SentStandIns {
  /// How many it keeps: more than can be sent at once.
  static const capacity = 32;

  final _pictures = <String, LocalFile>{};

  /// The picture message [clientId]'s outgoing bubble last showed, if any.
  LocalFile? operator [](String clientId) => _pictures[clientId];

  /// Keeps [picture], what message [clientId]'s outgoing bubble shows,
  /// dropping the oldest past [capacity].
  void leave(String clientId, LocalFile picture) {
    _pictures
      ..remove(clientId)
      ..[clientId] = picture;
    if (_pictures.length > capacity) {
      _pictures.remove(_pictures.keys.first);
    }
  }
}

/// The stand-ins outgoing bubbles leave for their sent ones.
@Riverpod(keepAlive: true)
SentStandIns sentStandIns(Ref ref) {
  // A new user's messages start afresh.
  ref.watch(activeSessionProvider);
  return SentStandIns();
}
