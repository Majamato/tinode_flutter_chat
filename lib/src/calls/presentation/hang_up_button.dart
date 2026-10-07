import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_control_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Ends the call; watches nothing.
class HangUpButton extends ConsumerWidget {
  const HangUpButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return CallControlButton(
      icon: Icons.call_end,
      tooltip: TinodeChatStrings.of(context).hangUp,
      color: colors.error,
      foregroundColor: colors.onError,
      onPressed: () => ref.read(callControllerProvider.notifier).hangUp(),
    );
  }
}
