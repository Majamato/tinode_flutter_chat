import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Moves the call between the earpiece and the loudspeaker; watches only
/// which one plays it. It turns white while the loudspeaker plays.
class SpeakerButton extends ConsumerWidget {
  const SpeakerButton({this.labelled = false, this.size = 64, super.key});

  /// Whether the button has its word below it.
  final bool labelled;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      callControllerProvider.select((c) => c?.speakerOn ?? false),
    );
    final strings = TinodeChatStrings.of(context);
    return CallRoundButton(
      icon: Icon(TinodeChatIcons.of(context).speaker),
      tooltip: on ? strings.speakerOff : strings.speakerOn,
      label: labelled ? strings.callSpeakerLabel : null,
      active: on,
      size: size,
      onPressed: () =>
          unawaited(ref.read(callControllerProvider.notifier).toggleSpeaker()),
    );
  }
}
