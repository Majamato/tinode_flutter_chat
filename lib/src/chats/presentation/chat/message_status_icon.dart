import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Where one of the user's messages stands: waiting (a clock), refused
/// (an error mark), or taken by the server ([status] null): one tick when
/// sent, two when every other member received it, two in the read colour
/// when all of them read it.
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    required this.color,
    this.status,
    this.receipt,
    super.key,
  });

  static const _size = 14.0;

  final OutgoingStatus? status;

  /// How far a message the server took got; sent when null.
  final MessageReceipt? receipt;

  /// The colour of the bubble's text, for the clock and the ticks.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final (icon, label, tint) = switch ((status, receipt)) {
      (null, MessageReceipt.read) => (
        Icons.done_all,
        strings.messageRead,
        TinodeChatTheme.of(context).readReceiptColor,
      ),
      (null, MessageReceipt.delivered) => (
        Icons.done_all,
        strings.messageDelivered,
        color,
      ),
      (null, MessageReceipt.sent || null) => (
        Icons.done,
        strings.messageSent,
        color,
      ),
      (OutgoingStatus.queued || OutgoingStatus.sending, _) => (
        Icons.schedule,
        strings.messageWaiting,
        color,
      ),
      (OutgoingStatus.failed, _) => (
        Icons.error_outline,
        strings.messageNotSent,
        Theme.of(context).colorScheme.error,
      ),
    };
    return Icon(icon, size: _size, color: tint, semanticLabel: label);
  }
}
