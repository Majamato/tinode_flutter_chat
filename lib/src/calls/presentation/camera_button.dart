import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_control_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Stops and resumes sending video; watches only whether it is on.
class CameraButton extends ConsumerWidget {
  const CameraButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      callControllerProvider.select((c) => c?.cameraOn ?? true),
    );
    final strings = TinodeChatStrings.of(context);

    return CallControlButton(
      icon: on ? Icons.videocam : Icons.videocam_off,
      tooltip: on ? strings.turnCameraOff : strings.turnCameraOn,
      active: !on,
      onPressed: () => ref.read(callControllerProvider.notifier).toggleCamera(),
    );
  }
}
