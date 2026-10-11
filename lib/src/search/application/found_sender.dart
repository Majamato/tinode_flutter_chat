import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/search/domain/found_sender.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';

part 'found_sender.g.dart';

/// Who sent a message found in [topic], from the user ID [from]. A group
/// member's name comes from the chat's members, kept on the device.
@riverpod
FoundSender foundSender(Ref ref, String topic, String? from) {
  if (from != null && from == ref.watch(currentUserIdProvider)) {
    return const FoundSender.own();
  }
  if (TopicKind.of(topic) != TopicKind.group) {
    return const FoundSender.chat();
  }
  return FoundSender.member(
    ref.watch(
      chatMembersControllerProvider(topic).select((m) => m[from]?.name),
    ),
  );
}
