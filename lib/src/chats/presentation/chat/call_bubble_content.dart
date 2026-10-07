import 'package:flutter/material.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
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

    final title = switch ((outgoing, call.audioOnly)) {
      (true, true) => strings.outgoingVoiceCall,
      (true, false) => strings.outgoingVideoCall,
      (false, true) => strings.incomingVoiceCall,
      (false, false) => strings.incomingVideoCall,
    };

    final status = switch (call.state) {
      CallState.finished => formatCallDuration(call.duration ?? Duration.zero),
      CallState.missed => outgoing ? strings.callNoAnswer : strings.callMissed,
      CallState.declined => strings.callDeclined,
      CallState.disconnected || CallState.busy => strings.callNotConnected,
      CallState.started ||
      CallState.accepted ||
      CallState.unknown => strings.callInProgress,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch ((outgoing, call.failed)) {
            (true, false) => Icons.call_made,
            (false, false) => Icons.call_received,
            (true, true) => Icons.call_missed_outgoing,
            (false, true) => Icons.call_missed,
          },
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: textTheme.bodyMedium?.copyWith(color: color)),
              Text(
                status,
                style: textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
