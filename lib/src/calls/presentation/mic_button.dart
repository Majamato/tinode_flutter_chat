import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Mutes and unmutes the microphone; watches only whether it is on. It
/// turns white with a slashed mic while muted.
class MicButton extends ConsumerWidget {
  const MicButton({this.labelled = false, this.size = 64, super.key});

  /// Whether the button has its word below it.
  final bool labelled;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      callControllerProvider.select((c) => c?.micOn ?? true),
    );
    final strings = TinodeChatStrings.of(context);
    return CallRoundButton(
      icon: Icon(on ? Icons.mic_rounded : Icons.mic_off_rounded),
      tooltip: on ? strings.muteMicrophone : strings.unmuteMicrophone,
      label: labelled ? strings.callMuteLabel : null,
      active: !on,
      size: size,
      onPressed: () =>
          ref.read(callControllerProvider.notifier).toggleMicrophone(),
    );
  }
}
