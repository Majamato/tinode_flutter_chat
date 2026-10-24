import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_minimized.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The chevron that shrinks the call to the call bar, back to the chats;
/// watches nothing.
class CallMinimizeButton extends ConsumerWidget {
  const CallMinimizeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    onPressed: () => ref.read(callMinimizedProvider.notifier).minimize(),
    tooltip: TinodeChatStrings.of(context).minimizeCall,
    iconSize: 30,
    color: TinodeChatTheme.of(context).onCallColor,
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    padding: EdgeInsets.zero,
    icon: const Icon(Icons.keyboard_arrow_down_rounded),
  );
}
