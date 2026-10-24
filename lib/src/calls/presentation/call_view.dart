import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/video_call_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/voice_call_view.dart';

/// The call screen while calling or in a call: the voice call or the video
/// call. Watches only the call's topic and whether it has video.
class CallView extends ConsumerWidget {
  const CallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(
      callControllerProvider.select(
        (c) => c == null ? null : (topic: c.topic, video: !c.audioOnly),
      ),
    );
    return switch (call) {
      null => const SizedBox.shrink(),
      (:final topic, video: true) => VideoCallView(topic: topic),
      (:final topic, video: false) => VoiceCallView(topic: topic),
    };
  }
}
