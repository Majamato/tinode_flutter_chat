import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_record_texts.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The inside of a call message's bubble: direction, voice or video, and
/// how the call went. Watches nothing; its bubble passes the record in.
class CallBubbleContent extends StatelessWidget {
  const CallBubbleContent({
    required this.call,
    required this.outgoing,
    required this.color,
    super.key,
  });

  final CallRecord call;

  /// The user made the call.
  final bool outgoing;

  /// Text color of the bubble.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final statusColor = call.failed
        ? TinodeChatTheme.of(context).missedCallColor
        : color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          call.icon(TinodeChatIcons.of(context), outgoing: outgoing),
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                call.title(strings, outgoing: outgoing),
                style: textTheme.bodyMedium?.copyWith(color: color),
              ),
              Text(
                call.status(strings, outgoing: outgoing),
                style: textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
