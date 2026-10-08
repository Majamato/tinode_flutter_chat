import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Where one of the user's messages stands: waiting (a clock), refused
/// (an error mark) or taken by the server ([status] null, a tick).
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({required this.color, this.status, super.key});

  static const _size = 14.0;

  final OutgoingStatus? status;

  /// The colour of the bubble's text, for the clock and the tick.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final (icon, label, tint) = switch (status) {
      null => (Icons.done, strings.messageSent, color),
      OutgoingStatus.queued ||
      OutgoingStatus.sending => (Icons.schedule, strings.messageWaiting, color),
      OutgoingStatus.failed => (
        Icons.error_outline,
        strings.messageNotSent,
        Theme.of(context).colorScheme.error,
      ),
    };
    return Icon(icon, size: _size, color: tint, semanticLabel: label);
  }
}
