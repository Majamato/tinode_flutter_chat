import 'dart:async';

import 'package:clock/clock.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/typing_members.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';

part 'typing_controller.g.dart';

/// How long a member counts as typing after their last key press.
const typingTimeout = Duration(seconds: 5);

/// The shortest time between two typing notes this user sends.
const typingThrottle = Duration(seconds: 3);

/// Typing in one open chat, both ways: the user IDs of the members typing
/// now, first to start first, and [typed] for the user's own key presses.
///
/// A member stops typing after [typingTimeout] without a key press, or when
/// their message arrives.
@riverpod
class TypingController extends _$TypingController {
  final _timeouts = <String, Timer>{};
  DateTime? _lastSent;

  @override
  List<String> build(String topic) {
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _lastSent = null;
    ref.onDispose(_cancelTimeouts);
    if (session == null) {
      return const [];
    }

    final subscriptions = [
      session.info
          .where(
            (i) =>
                i.topic == topic &&
                i.event == InfoEvent.typing &&
                i.from != null &&
                i.from != me,
          )
          .listen((i) => _typing(i.from!)),
      session.messages
          .where((m) => m.topic == topic)
          .listen((m) => _stopped(m.from)),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
    });
    return const [];
  }

  /// The user typed in the composer: tells the other members, at most once
  /// per [typingThrottle].
  void typed() {
    final now = clock.now();
    if (_lastSent case final last? when now.difference(last) < typingThrottle) {
      return;
    }
    _lastSent = now;
    ref.read(activeSessionProvider)?.sendTyping(topic);
  }

  void _typing(String userId) {
    _timeouts.remove(userId)?.cancel();
    _timeouts[userId] = Timer(typingTimeout, () => _stopped(userId));
    if (!state.contains(userId)) {
      state = List.unmodifiable([...state, userId]);
    }
  }

  void _stopped(String? userId) {
    _timeouts.remove(userId)?.cancel();
    if (state.contains(userId)) {
      state = List.unmodifiable(state.where((id) => id != userId));
    }
  }

  void _cancelTimeouts() {
    for (final timer in _timeouts.values) {
      timer.cancel();
    }
    _timeouts.clear();
  }
}

/// Who is typing in [topic], by name. In a direct chat the title already
/// names the peer.
@riverpod
TypingMembers typingMembers(Ref ref, String topic) {
  final typing = ref.watch(typingControllerProvider(topic));
  if (typing.isEmpty) {
    return const TypingMembers();
  }
  final direct = TopicKind.of(topic) == TopicKind.direct;
  return ref.watch(
    chatMembersControllerProvider(topic).select(
      (members) => TypingMembers(
        names: [for (final id in typing) direct ? null : members[id]?.name],
        direct: direct,
      ),
    ),
  );
}
