import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_failure.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Whether the call ended because a connection dropped, the case in which
/// the call screen offers [CallLostActions].
bool isLostCall({required bool over, CallFailure? failure}) =>
    over &&
    (failure == CallFailure.callLost || failure == CallFailure.connectionLost);

/// In place of the controls of a call that ended because a connection
/// dropped: call the same peer again, or close. Calling again waits for
/// the chat server while it reconnects. Watches whether the call had video
/// and whether the session is reconnecting.
class CallLostActions extends ConsumerWidget {
  const CallLostActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final video = ref.watch(
      callControllerProvider.select((c) => !(c?.audioOnly ?? true)),
    );
    final offline = ref.watch(reconnectingControllerProvider);
    final strings = TinodeChatStrings.of(context);
    final controller = ref.read(callControllerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallRoundButton(
          icon: Icon(icons.close),
          tooltip: strings.closeCall,
          label: strings.closeCall,
          onPressed: controller.closeEnded,
        ),
        Opacity(
          opacity: offline ? 0.4 : 1,
          child: CallRoundButton(
            icon: Icon(video ? icons.videoCall : icons.voiceCall),
            tooltip: strings.callAgain,
            label: strings.callAgain,
            style: CallButtonStyle.accept,
            onPressed: offline ? null : () => unawaited(controller.callAgain()),
          ),
        ),
      ],
    );
  }
}
