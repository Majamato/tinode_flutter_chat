import 'package:tinode_flutter_chat/src/chats/domain/typing_members.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The text that says who is typing; empty when nobody is.
String typingMessage(TinodeChatStrings strings, TypingMembers typing) {
  if (typing.isEmpty) {
    return '';
  }
  if (typing.direct) {
    return strings.typingDirect;
  }
  String name(String? name) => name ?? strings.unknownMember;
  return switch (typing.names) {
    [final one] => strings.typingOne(name(one)),
    [final first, final second] => strings.typingTwo(name(first), name(second)),
    final names => strings.typingMany(names.length),
  };
}
