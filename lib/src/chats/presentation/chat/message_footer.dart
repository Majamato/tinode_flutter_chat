import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_footer.dart';

/// The footer of a numbered message: its time and, on the user's own, how
/// far it got. Only this rebuilds when a member reads it.
class MessageFooter extends ConsumerWidget {
  const MessageFooter({
    required this.topic,
    required this.seq,
    required this.time,
    required this.color,
    this.own = false,
    super.key,
  });

  final String topic;
  final int seq;
  final DateTime time;

  /// The colour of the bubble's text.
  final Color color;
  final bool own;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BubbleFooter(
    time: time,
    color: color,
    own: own,
    receipt: own ? ref.watch(messageReceiptProvider(topic, seq)) : null,
  );
}
