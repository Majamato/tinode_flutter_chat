import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_local_preview.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_remote_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/camera_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/hang_up_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/mic_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/speaker_button.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/switch_camera_button.dart';

/// The call screen while calling or in a call: the peer, the user's own
/// camera and the controls. Watches only the call's topic and whether it
/// has video.
class CallView extends ConsumerWidget {
  const CallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(
      callControllerProvider.select(
        (c) => c == null ? null : (topic: c.topic, video: !c.audioOnly),
      ),
    );
    if (call == null) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Theme.of(context).colorScheme.inverseSurface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CallRemoteView(topic: call.topic),
          const Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CallLocalPreview(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    const MicButton(),
                    if (call.video) ...const [
                      CameraButton(),
                      SwitchCameraButton(),
                    ],
                    const SpeakerButton(),
                    const HangUpButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
