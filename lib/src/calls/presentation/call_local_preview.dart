import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_video_view.dart';

/// The user's own camera in a corner of a video call; hidden while the
/// camera is off. Watches the local stream and the camera state.
class CallLocalPreview extends ConsumerWidget {
  const CallLocalPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:stream, :show, :front) = ref.watch(
      callControllerProvider.select(
        (c) => (
          stream: c?.localStream,
          show: c != null && !c.audioOnly && c.cameraOn,
          front: c?.frontCamera ?? true,
        ),
      ),
    );
    if (stream == null || !show) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 110,
        height: 160,
        child: CallVideoView(stream: stream, mirror: front),
      ),
    );
  }
}
