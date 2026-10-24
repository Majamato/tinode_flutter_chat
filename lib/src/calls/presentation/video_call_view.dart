import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_avatar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_backdrop.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_local_preview.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_lost_actions.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_minimize_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_status_text.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_video_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/camera_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/hang_up_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/mic_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/switch_camera_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The video call: the peer's video full-bleed (a still backdrop with
/// their avatar until it arrives), the user's own camera in a corner, and
/// the controls. A tap on the video hides or shows the name on top and the
/// floating control pill; the self-view moves up while they are hidden.
/// Once a dropped connection ended the call, Call again and Close take the
/// pill's place, shown whatever the tap did. Watches the remote stream and
/// whether the call was lost.
class VideoCallView extends ConsumerStatefulWidget {
  const VideoCallView({required this.topic, super.key});

  final String topic;

  @override
  ConsumerState<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends ConsumerState<VideoCallView> {
  static const _pipMove = Duration(milliseconds: 400);
  static const _pillHeight = 84.0;

  var _controls = true;

  void _toggleControls() => setState(() => _controls = !_controls);

  @override
  Widget build(BuildContext context) {
    final (:remote, :lost) = ref.watch(
      callControllerProvider.select(
        (c) => (
          remote: c?.remoteStream,
          lost: isLostCall(over: c?.isOver ?? false, failure: c?.failure),
        ),
      ),
    );
    final controls = _controls || lost;
    final theme = TinodeChatTheme.of(context);
    final strings = TinodeChatStrings.of(context);
    final padding = MediaQuery.paddingOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final onCall = theme.onCallColor;
    return Material(
      color: theme.callBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: strings.toggleCallControls,
            child: GestureDetector(
              onTap: _toggleControls,
              behavior: HitTestBehavior.opaque,
              child: remote == null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const CallBackdrop(video: true),
                        Center(
                          child: CallAvatar(topic: widget.topic, size: 96),
                        ),
                      ],
                    )
                  : CallVideoView(stream: remote),
            ),
          ),
          _Fading(
            shown: controls,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 200 + padding.top,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.callShadeColor,
                            theme.callShadeColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 16 + CallLocalPreview.size.width + 16,
                  top: padding.top + 4,
                  child: Row(
                    children: [
                      const CallMinimizeButton(),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DefaultTextStyle.merge(
                              style: TextStyle(
                                color: onCall,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              child: ChatTitle(topic: widget.topic),
                            ),
                            CallStatusText(
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: onCall.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: still ? Duration.zero : _pipMove,
            curve: theme.springCurve,
            right: 16,
            top: padding.top + (controls ? 66 : 8),
            child: const CallLocalPreview(),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: padding.bottom + 34,
            height: _pillHeight,
            child: lost
                ? const CallLostActions()
                : _Fading(
                    shown: controls,
                    slide: still ? 0 : 40 / _pillHeight,
                    child: const _ControlPill(),
                  ),
          ),
        ],
      ),
    );
  }
}

/// [child] while [shown]; otherwise faded out, moved down by [slide] of
/// its height, and out of reach of taps and screen readers.
class _Fading extends StatelessWidget {
  const _Fading({required this.shown, required this.child, this.slide = 0});

  final bool shown;
  final double slide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return IgnorePointer(
      ignoring: !shown,
      child: ExcludeSemantics(
        excluding: !shown,
        child: AnimatedSlide(
          offset: Offset(0, shown ? 0 : slide),
          duration: theme.springDuration,
          curve: theme.springCurve,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: theme.fadeDuration,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The floating glass pill: flip camera, camera, mute and end.
class _ControlPill extends StatelessWidget {
  const _ControlPill();

  static const _radius = BorderRadius.all(Radius.circular(42));
  static const _button = 60.0;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return ClipRRect(
      borderRadius: _radius,
      child: BackdropFilter(
        filter: glassFilter(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.callPillColor,
            borderRadius: _radius,
            border: Border.all(color: theme.callPillEdgeColor),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Center(child: SwitchCameraButton(size: _button)),
                ),
                Expanded(
                  child: Center(child: CameraButton(size: _button)),
                ),
                Expanded(
                  child: Center(child: MicButton(size: _button)),
                ),
                Expanded(
                  child: Center(child: HangUpButton(size: _button)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
