import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Ends the call, red with a red glow; watches nothing.
class HangUpButton extends ConsumerWidget {
  const HangUpButton({this.labelled = false, this.size = 64, super.key});

  /// Whether the button has its word below it.
  final bool labelled;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    return CallRoundButton(
      icon: const Icon(Icons.call_end_rounded),
      tooltip: strings.hangUp,
      label: labelled ? strings.callEndLabel : null,
      style: CallButtonStyle.danger,
      size: size,
      onPressed: () => ref.read(callControllerProvider.notifier).hangUp(),
    );
  }
}
