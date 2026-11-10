import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_progress_ring.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/outgoing_attachment_view.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/domain/bubble_status.dart';
import 'package:tinode_flutter_chat/src/chats/domain/tinode_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_builder_scope.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_footer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_slot.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/outgoing_actions_sheet.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/send_pop.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_bubble_content.dart';

/// A message of the user's still in the outbox, with its status; an
/// image, video, file or recording shows from its staged copy (a video from
/// its poster) while it compresses and uploads (a recording plays from
/// it). One just sent pops in. An X on an attachment on its way stops it; a
/// long press offers to retry or discard it.
class OutgoingBubble extends ConsumerWidget {
  const OutgoingBubble({
    required this.topic,
    required this.clientId,
    super.key,
  });

  /// Messages created this recently pop in; older ones were waiting when
  /// the chat opened.
  static const _fresh = Duration(seconds: 1);

  final String topic;
  final String clientId;

  /// Stops the message on its way; a failure leaves the bubble as it is.
  void _cancel(WidgetRef ref) => unawaited(
    ref
        .read(chatControllerProvider(topic).notifier)
        .discard(clientId)
        .then((_) {}, onError: (_) {}),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(outgoingMessageProvider(topic, clientId));
    final run = ref.watch(outgoingRunProvider(topic, clientId));
    if (message == null) {
      return const SizedBox.shrink();
    }
    final theme = TinodeChatTheme.of(context);
    final foreground = theme.onOwnBubbleColor;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: foreground);
    final attachment = message.attachment;
    final text = attachment?.caption ?? message.content.text;
    final onPhoto = (attachment?.isMedia ?? false) && text.isEmpty;
    final footer = BubbleFooter(
      time: message.createdAt,
      color: onPhoto ? PhotoTimeChip.footerColor : theme.ownMetaColor,
      own: true,
      status: message.status,
    );

    Widget bubble = BubbleFrame(
      own: true,
      tail: run.endsRun,
      padding: switch (attachment) {
        null => BubbleFrame.textPadding,
        final a when a.isMedia => BubbleFrame.photoPadding,
        _ => BubbleFrame.tilePadding,
      },
      onLongPress: () => unawaited(
        showChatSheet<void>(
          context,
          builder: (_) =>
              OutgoingActionsSheet(topic: topic, clientId: clientId),
        ),
      ),
      body: switch (attachment) {
        OutgoingAttachment(:final voice?, :final stagedId, :final mimeType) =>
          VoiceBubbleContent(
            note: voice,
            source: StagedVoiceSource(stagedId, mimeType: mimeType),
            own: true,
            footer: footer,
            busy: message.status == OutgoingStatus.queued
                ? AttachmentProgressRing(
                    topic: topic,
                    clientId: clientId,
                    compress: false,
                    color: foreground,
                  )
                : null,
          ),
        final attachment? when onPhoto => Stack(
          children: [
            OutgoingAttachmentView(
              topic: topic,
              clientId: clientId,
              attachment: attachment,
              uploading: message.status == OutgoingStatus.queued,
              color: foreground,
              onCancel: () => _cancel(ref),
            ),
            PositionedDirectional(
              end: 6,
              bottom: 6,
              child: PhotoTimeChip(child: footer),
            ),
          ],
        ),
        final attachment? => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutgoingAttachmentView(
              topic: topic,
              clientId: clientId,
              attachment: attachment,
              uploading: message.status == OutgoingStatus.queued,
              color: foreground,
              onCancel: () => _cancel(ref),
            ),
            Padding(
              padding: attachment.isMedia
                  ? const EdgeInsets.fromLTRB(8, 2, 8, 6)
                  : const EdgeInsets.only(top: 4),
              child: text.isEmpty
                  ? Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: footer,
                    )
                  : BubbleTextLayout(
                      text: Text(text, style: textStyle),
                      footer: footer,
                    ),
            ),
          ],
        ),
        null => BubbleTextLayout(
          text: Text(text, style: textStyle),
          footer: footer,
        ),
      },
    );

    if (BubbleBuilderScope.maybeOf(context) case final builder?) {
      bubble = builder(
        context,
        TinodeBubble(
          topic: topic,
          own: true,
          text: text,
          time: message.createdAt,
          kind: switch (attachment) {
            null => TinodeBubbleKind.text,
            OutgoingAttachment(voice: _?) => TinodeBubbleKind.voice,
            _ => TinodeBubbleKind.attachment,
          },
          startsRun: run.startsRun,
          endsRun: run.endsRun,
          status: bubbleStatusOfOutbox(message.status),
        ),
        bubble,
      );
    }
    return MessageSlot(
      run: run,
      time: message.createdAt,
      child: SendPop(
        animate: clock.now().difference(message.createdAt) < _fresh,
        child: bubble,
      ),
    );
  }
}
