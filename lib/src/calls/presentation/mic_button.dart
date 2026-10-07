import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_control_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Mutes and unmutes the microphone; watches only whether it is on.
class MicButton extends ConsumerWidget {
  const MicButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      callControllerProvider.select((c) => c?.micOn ?? true),
    );
    final strings = TinodeChatStrings.of(context);
    return CallControlButton(
      icon: on ? Icons.mic : Icons.mic_off,
      tooltip: on ? strings.muteMicrophone : strings.unmuteMicrophone,
      active: !on,
      onPressed: () =>
          ref.read(callControllerProvider.notifier).toggleMicrophone(),
    );
  }
}
