import 'dart:typed_data';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/latest_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What a chat's newest message is, for the preview line of its tile.
enum ChatPreviewKind { text, photo, video, file, voice, call }

/// The newest cached message of a chat, as its tile's preview line shows
/// it. Built from the cache, which the session fills from the server: Tinode
/// sends no message in the chat list.
final class ChatPreview with ValueObject {
  const ChatPreview({
    required this.seq,
    required this.kind,
    this.text = '',
    this.isOwn = false,
    this.senderName,
    this.call,
    this.photo,
  });

  /// The preview of [latest] in a chat of [kind], its message as its
  /// updates leave it; null when the cache holds no message to show.
  /// [members] name a group's senders; [me] tells the user's own message.
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
      VideoAttachment() => (ChatPreviewKind.video, message.caption, null),
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
      kind: previewKind,
      text: text.replaceAll('\n', ' ').trim(),
      isOwn: message.isOwn,
      senderName: kind == TopicKind.group && !message.isOwn
          ? members[message.from]?.name
          : null,
      call: message.call,
      photo: photo,
    );
  }

  final int seq;

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

  /// A call to the user that they didn't take.
  bool get isMissedCall => !isOwn && (call?.failed ?? false);

  @override
  List<Object?> get props => [seq, kind, text, isOwn, senderName, call, photo];
}
