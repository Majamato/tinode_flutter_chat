import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_preview.dart';
import 'package:tinode_flutter_chat/src/offline/domain/latest_message.dart';

import '../../support/fixtures.dart';

void main() {
  DataMessage drafty(String topic, int seq, Drafty content, {String? from}) =>
      DataMessage(
        topic: topic,
        seq: seq,
        from: from ?? bob,
        time: at(seq),
        content: DraftyContent(content),
      );

  ChatPreview? preview(
    DataMessage message, {
    List<DataMessage> updates = const [],
    ChatMembers members = const ChatMembers(),
  }) => ChatPreview.of(
    LatestMessage(
      newestSeq: updates.lastOrNull?.seq ?? message.seq,
      message: message,
      updates: updates,
    ),
    me: alice,
    kind: TopicKind.of(message.topic),
    members: members,
  );

  test('text on one line', () {
    final text = preview(message(bob, 3, text: 'see\nyou'))!;
    expect(
      (text.kind, text.text, text.isOwn),
      (ChatPreviewKind.text, 'see you', false),
    );
  });

  test('a photo with its caption and inline bytes', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final photo = preview(
      drafty(
        bob,
        3,
        Drafty.image(
          DraftyImage(mimeType: 'image/jpeg', inlineData: base64.encode(bytes)),
          caption: 'beach',
        ),
      ),
    )!;
    expect((photo.kind, photo.text), (ChatPreviewKind.photo, 'beach'));
    expect(photo.photo, bytes);
  });

  test('a video by its caption, else as a video', () {
    final video = preview(
      drafty(
        bob,
        3,
        Drafty.video(const DraftyVideo(ref: '/f/v'), caption: 'goal!'),
      ),
    )!;
    expect((video.kind, video.text), (ChatPreviewKind.video, 'goal!'));

    final bare = preview(
      drafty(bob, 4, Drafty.video(const DraftyVideo(ref: '/f/v'))),
    )!;
    expect((bare.kind, bare.text), (ChatPreviewKind.video, ''));
  });

  test('a file by its name, a voice note by its audio type', () {
    final file = preview(
      drafty(
        bob,
        3,
        Drafty.file(const DraftyFile(name: 'logo.pdf', ref: '/f/1')),
      ),
    )!;
    expect((file.kind, file.text), (ChatPreviewKind.file, 'logo.pdf'));

    final voice = preview(
      drafty(
        bob,
        4,
        Drafty.file(const DraftyFile(mimeType: 'audio/aac', ref: '/f/2')),
      ),
    )!;
    expect(voice.kind, ChatPreviewKind.voice);

    final recording = preview(
      drafty(
        bob,
        5,
        Drafty.audio(
          const DraftyAudio(ref: '/f/3', duration: Duration(seconds: 4)),
        ),
      ),
    )!;
    expect((recording.kind, recording.text), (ChatPreviewKind.voice, ''));
  });

  test('a call as its updates leave it: missed only when to the user', () {
    final call = DataMessage(
      topic: bob,
      seq: 5,
      from: bob,
      time: at(5),
      head: const MessageHead(callState: CallState.started, audioOnly: true),
      content: DraftyContent(Drafty.videoCall(audioOnly: true)),
    );
    final missed = DataMessage(
      topic: bob,
      seq: 6,
      from: bob,
      time: at(6),
      head: const MessageHead(replaces: ':5', callState: CallState.missed),
      content: DraftyContent(Drafty.videoCall()),
    );
    final toMe = preview(call, updates: [missed])!;
    expect(toMe.kind, ChatPreviewKind.call);
    expect(toMe.call?.audioOnly, isTrue);
    expect(toMe.isMissedCall, isTrue);

    final mine = preview(
      DataMessage(
        topic: bob,
        seq: 5,
        from: alice,
        time: at(5),
        head: const MessageHead(callState: CallState.missed),
        content: DraftyContent(Drafty.videoCall()),
      ),
    )!;
    expect(mine.isMissedCall, isFalse);
  });

  test("a group names the sender, but not of the user's own", () {
    final members = const ChatMembers().withMembers([
      member(alice, name: 'Alice', read: 9, received: 9),
      member(bob, name: 'Bob', read: 8, received: 9),
      member(carol, name: 'Carol', read: 9, received: 9),
    ]);
    final theirs = preview(message(friends, 9), members: members)!;
    expect(theirs.senderName, 'Bob');

    final mine = preview(message(friends, 9, from: alice), members: members)!;
    expect(mine.senderName, isNull);

    // A direct chat names no one.
    expect(preview(message(bob, 9), members: members)!.senderName, isNull);
  });

  test('no message, only updates of older ones: no preview', () {
    expect(
      ChatPreview.of(
        const LatestMessage(newestSeq: 4),
        me: alice,
        kind: TopicKind.direct,
      ),
      isNull,
    );
  });
}
