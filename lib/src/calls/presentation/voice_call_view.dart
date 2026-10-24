import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_avatar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_backdrop.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_entrance.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_lost_actions.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_minimize_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_reconnecting_pill.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_status_text.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/hang_up_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/mic_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/speaker_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The voice call, always dark: the chevron back to the chats and the
/// reconnecting pill on top, the peer's avatar with rings pulsing until
/// the call connects, their name and the call's status, and Speaker, Mute
/// and End; Call again and Close once a dropped connection ended it. Its
/// content fades up into place. Watches whether the call is connected and
/// whether it was lost.
class VoiceCallView extends ConsumerWidget {
  const VoiceCallView({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:connected, :lost) = ref.watch(
      callControllerProvider.select(
        (c) => (
          connected: c?.stage == CallStage.connected,
          lost: isLostCall(over: c?.isOver ?? false, failure: c?.failure),
        ),
      ),
    );
    final theme = TinodeChatTheme.of(context);
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      CallMinimizeButton(),
                      Expanded(child: Center(child: CallReconnectingPill())),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.45),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CallEntrance(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CallAvatar(topic: topic, rings: !connected),
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
                                child: ChatTitle(topic: topic),
                              ),
                            ),
                            const SizedBox(height: 6),
                            CallStatusText(
                              showReconnecting: false,
                              style: TextStyle(
                                color: onCall.withValues(
                                  alpha: connected ? 0.95 : 0.9,
                                ),
                                fontSize: 17,
                                fontWeight: connected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: lost
                        ? const CallLostActions()
                        : const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: SpeakerButton(labelled: true),
                                ),
                              ),
                              Expanded(
                                child: Center(child: MicButton(labelled: true)),
                              ),
                              Expanded(
                                child: Center(
                                  child: HangUpButton(labelled: true),
                                ),
                              ),
                            ],
                          ),
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
