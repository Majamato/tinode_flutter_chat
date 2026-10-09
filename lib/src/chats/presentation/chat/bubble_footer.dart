import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_status_icon.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';

/// The time of a message and, on the user's own, its status.
class BubbleFooter extends StatelessWidget {
  const BubbleFooter({
    required this.time,
    required this.color,
    this.own = false,
    this.status,
    this.receipt,
    super.key,
  });

  final DateTime time;

  /// The colour of the bubble's text.
  final Color color;

  /// Shows the status: [status] while in the outbox, else [receipt].
  final bool own;
  final OutgoingStatus? status;
  final MessageReceipt? receipt;

  @override
  Widget build(BuildContext context) {
    final faded = color.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          MaterialLocalizations.of(context).messageTime(time),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: faded),
        ),
        if (own) ...[
          const SizedBox(width: 4),
          MessageStatusIcon(status: status, receipt: receipt, color: faded),
        ],
      ],
    );
  }
}
