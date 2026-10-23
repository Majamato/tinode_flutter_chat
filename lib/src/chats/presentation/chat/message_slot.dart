import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_run.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/date_chip.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The room a message takes in the list: the date above the first of a
/// day, a wider gap above the first of a run, then the [child].
class MessageSlot extends StatelessWidget {
  const MessageSlot({
    required this.run,
    required this.time,
    required this.child,
    super.key,
  });

  final MessageRun run;
  final DateTime time;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final spaced = Padding(
      padding: EdgeInsets.only(
        top: run.startsRun ? theme.newRunGap : theme.sameRunGap,
      ),
      child: child,
    );
    if (!run.startsDay) {
      return spaced;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateChip(time: time),
        spaced,
      ],
    );
  }
}
