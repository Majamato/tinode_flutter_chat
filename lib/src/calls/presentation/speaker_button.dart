import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_control_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Moves the call between the earpiece and the loudspeaker; watches only
/// which one plays it.
class SpeakerButton extends ConsumerWidget {
  const SpeakerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      callControllerProvider.select((c) => c?.speakerOn ?? false),
    );
    final strings = TinodeChatStrings.of(context);
    return CallControlButton(
      icon: on ? Icons.volume_up : Icons.volume_down,
      tooltip: on ? strings.speakerOff : strings.speakerOn,
      active: on,
      onPressed: () =>
          unawaited(ref.read(callControllerProvider.notifier).toggleSpeaker()),
    );
  }
}
