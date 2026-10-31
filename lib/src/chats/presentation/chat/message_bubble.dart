import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/domain/bubble_status.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/tinode_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/attachment_message_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_builder_scope.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_bubble_content.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_actions_sheet.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_footer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_slot.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/sender_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/sender_name.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_bubble_content.dart';

/// One numbered message. A call message shows the call instead of its
/// text, a voice message its recording to play, and a message with
/// images or files shows them above its caption. The last of a run has
/// the tail; in a group, others' messages carry the sender's name and
/// avatar at the edges of a run. A long press offers to delete it. The
/// host's bubble builder, if any, gets the last word.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({required this.topic, required this.seq, super.key});

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(chatMessageProvider(topic, seq));
    final run = ref.watch(messageRunProvider(topic, seq));
    final (fromMember, showName) = ref.watch(
      messageSenderProvider(
        topic,
        seq,
      ).select((s) => (s != null, s?.showName ?? false)),
    );
    if (message == null) {
      return const SizedBox.shrink();
    }

    final theme = TinodeChatTheme.of(context);
    final own = message.isOwn;
    final foreground = own ? theme.onOwnBubbleColor : theme.onPeerBubbleColor;
    final attachments = message.attachments;
    final onPhoto =
        message.call == null &&
        AttachmentMessageBody.overPhoto(attachments, message.caption);
    final footer = MessageFooter(
      topic: topic,
      seq: seq,
      time: message.time,
      color: onPhoto
          ? PhotoTimeChip.footerColor
          : own
          ? theme.ownMetaColor
          : theme.peerMetaColor,
      own: own,
    );

    final (kind, padding, body, footerBelow) = switch (message) {
      ChatMessage(:final call?) => (
        TinodeBubbleKind.call,
        BubbleFrame.tilePadding,
        CallBubbleContent(call: call, outgoing: own, color: foreground),
        footer,
      ),
      ChatMessage(:final voice?) => (
        TinodeBubbleKind.voice,
        BubbleFrame.tilePadding,
        VoiceBubbleContent(
          note: voice.note,
          source: voice.sourceIn('$topic:$seq'),
          own: own,
          footer: footer,
        ),
        null,
      ),
      _ when attachments.isNotEmpty => (
        TinodeBubbleKind.attachment,
        AttachmentMessageBody.hasPhoto(attachments)
            ? BubbleFrame.photoPadding
            : BubbleFrame.tilePadding,
        AttachmentMessageBody(
          attachments: attachments,
          caption: message.caption,
          color: foreground,
          footer: footer,
        ),
        null,
      ),
      _ => (
        TinodeBubbleKind.text,
        BubbleFrame.textPadding,
        BubbleTextLayout(
          text: Text(
            message.caption,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: foreground),
          ),
          footer: footer,
        ),
        null,
      ),
    };

    final frame = BubbleFrame(
      own: own,
      tail: run.endsRun,
      padding: padding,
      onLongPress: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => MessageActionsSheet(topic: topic, seq: seq),
        ),
      ),
      header: showName ? SenderName(topic: topic, seq: seq) : null,
      body: body,
      footer: footerBelow,
    );
    var bubble = fromMember
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SenderAvatar(topic: topic, seq: seq),
              Expanded(child: frame),
            ],
          )
        : frame;

    if (BubbleBuilderScope.maybeOf(context) case final builder?) {
      // Watched only for the host's builder: the default bubble's footer
      // watches it on its own.
      final receipt = own
          ? ref.watch(messageReceiptProvider(topic, seq))
          : null;
      bubble = builder(
        context,
        TinodeBubble(
          topic: topic,
          seq: seq,
          senderId: message.from,
          own: own,
          text: message.caption,
          time: message.time,
          kind: kind,
          startsRun: run.startsRun,
          endsRun: run.endsRun,
          status: own ? bubbleStatusOfReceipt(receipt) : null,
        ),
        bubble,
      );
    }
    return MessageSlot(run: run, time: message.time, child: bubble);
  }
}
