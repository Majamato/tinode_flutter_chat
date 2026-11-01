import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_avatar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_backdrop.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_entrance.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A call to the user, ringing, on the voice call's moving background:
/// who calls with rings pulsing round their avatar, voice or video, and
/// round buttons to decline or accept. Watches the call's topic and
/// whether it has video.
class IncomingCallView extends ConsumerWidget {
  const IncomingCallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final call = ref.watch(
      callControllerProvider.select(
        (c) => c == null ? null : (topic: c.topic, audioOnly: c.audioOnly),
      ),
    );
    if (call == null) {
      return const SizedBox.shrink();
    }

    final strings = TinodeChatStrings.of(context);
    final theme = TinodeChatTheme.of(context);
    final controller = ref.read(callControllerProvider.notifier);
    final onCall = theme.onCallColor;

    return Material(
      color: theme.callBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CallBackdrop(),
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 56),
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CallEntrance(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CallAvatar(topic: call.topic, rings: true),
                            const SizedBox(height: 22),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: DefaultTextStyle.merge(
                                style: TextStyle(
                                  color: onCall,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                                child: ChatTitle(topic: call.topic),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              call.audioOnly
                                  ? strings.incomingVoiceCall
                                  : strings.incomingVideoCall,
                              style: TextStyle(
                                color: onCall.withValues(alpha: 0.9),
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                CallEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CallRoundButton(
                        icon: Icon(icons.hangUp),
                        tooltip: strings.declineCall,
                        label: strings.declineCall,
                        style: CallButtonStyle.danger,
                        onPressed: controller.decline,
                      ),
                      CallRoundButton(
                        icon: Icon(
                          call.audioOnly ? icons.voiceCall : icons.videoCall,
                        ),
                        tooltip: strings.acceptCall,
                        label: strings.acceptCall,
                        style: CallButtonStyle.accept,
                        onPressed: () => unawaited(controller.accept()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
