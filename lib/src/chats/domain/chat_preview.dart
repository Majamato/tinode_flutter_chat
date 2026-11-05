import 'dart:typed_data';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';
import 'package:tinode_flutter_chat/src/offline/domain/latest_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What a chat's newest message is, for the preview line of its tile.
enum ChatPreviewKind { text, photo, file, voice, call }

/// The newest cached message of a chat, as its tile's preview line shows
/// it. Built from the cache, which the session fills from the server: Tinode
/// sends no message in the chat list.
final class ChatPreview with ValueObject {
  const ChatPreview({
    required this.seq,
    required this.newestSeq,
    required this.kind,
    this.text = '',
    this.isOwn = false,
    this.senderName,
    this.call,
    this.photo,
    this.receipt,
  });

  /// The preview of [latest] in a chat of [kind], its message as its
  /// updates leave it; null when the cache holds no message to show.
  /// [members] name a group's senders and tell how far the user [me]'s
  /// message got.
  static ChatPreview? of(
    LatestMessage latest, {
    required String me,
    required TopicKind kind,
    ChatMembers members = const ChatMembers(),
  }) {
    final data = latest.message;
    if (data == null) {
      return null;
    }
    final message = latest.updates.fold(
      ChatMessage.fromData(data, me: me),
      (message, update) =>
          message.updatedBy(ChatMessage.fromData(update, me: me)),
    );
    final attachment = message.attachments.firstOrNull;
    final (previewKind, text, photo) = switch (attachment) {
      _ when message.call != null => (ChatPreviewKind.call, '', null),
      ImageAttachment(:final bytes) => (
        ChatPreviewKind.photo,
        message.caption,
        bytes,
      ),
      VoiceAttachment() => (ChatPreviewKind.voice, message.caption, null),
      FileAttachment(:final mimeType?) when mimeType.startsWith('audio/') => (
        ChatPreviewKind.voice,
        message.caption,
        null,
      ),
      FileAttachment(:final name) => (
        ChatPreviewKind.file,
        message.caption.isEmpty ? name ?? '' : message.caption,
        null,
      ),
      null => (ChatPreviewKind.text, message.caption, null),
    };
    return ChatPreview(
      seq: message.seq,
      newestSeq: latest.newestSeq,
      kind: previewKind,
      text: text.replaceAll('\n', ' ').trim(),
      isOwn: message.isOwn,
      senderName: kind == TopicKind.group && !message.isOwn
          ? members[message.from]?.name
          : null,
      call: message.call,
      photo: photo,
      receipt: message.isOwn
          ? members.receiptOf(message.seq, me: me, kind: kind)
          : null,
    );
  }

  final int seq;

  /// The newest seq cached for the chat, updates included; see [isBehind].
  final int newestSeq;

  final ChatPreviewKind kind;

  /// The text on one line: a message's text, an attachment's caption, or a
  /// file's name when it has none. Empty for calls.
  final String text;

  /// The user sent it.
  final bool isOwn;

  /// Who sent it, in a group, when the cache knows their name.
  final String? senderName;

  /// Set for a call.
  final CallRecord? call;

  /// A photo's inline preview, when it came inline.
  final Uint8List? photo;

  /// How far the user's own message got; null for others'.
  final MessageReceipt? receipt;

  /// A call to the user that they didn't take.
  bool get isMissedCall => !isOwn && (call?.failed ?? false);

  /// The chat has messages past what the cache holds: the preview is no
  /// longer the newest.
  bool isBehind(int lastSeq) => lastSeq > newestSeq;

  @override
  List<Object?> get props => [
    seq,
    newestSeq,
    kind,
    text,
    isOwn,
    senderName,
    call,
    photo,
    receipt,
  ];
}
