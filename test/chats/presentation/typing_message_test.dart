import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/domain/typing_members.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_message.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() {
  const strings = TinodeChatStrings();

  String text(List<String?> names, {bool direct = false}) =>
      typingMessage(strings, TypingMembers(names: names, direct: direct));

  test('names one or two members, counts more', () {
    expect(text([]), '');
    expect(text(['Bob']), 'Bob is typing…');
    expect(text(['Bob', null]), 'Bob and Unknown are typing…');
    expect(text(['Bob', 'Carol', 'Dave']), '3 people are typing…');
  });

  test('a direct chat needs no name', () {
    expect(text([null], direct: true), 'typing…');
  });

  test('the host can reword them', () {
    const spanish = TinodeChatStrings(typingOne: _escribe);
    expect(
      typingMessage(spanish, const TypingMembers(names: ['Bob'])),
      'Bob está escribiendo…',
    );
  });
}

String _escribe(String name) => '$name está escribiendo…';
