import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Stops and resumes sending video; watches only whether it is on. It
/// turns white with a slashed camera while the camera is off.
class CameraButton extends ConsumerWidget {
  const CameraButton({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      callControllerProvider.select((c) => c?.cameraOn ?? true),
    );
    final strings = TinodeChatStrings.of(context);
    return CallRoundButton(
      icon: Icon(on ? Icons.videocam_rounded : Icons.videocam_off_rounded),
      tooltip: on ? strings.turnCameraOff : strings.turnCameraOn,
      active: !on,
      size: size,
      onPressed: () => ref.read(callControllerProvider.notifier).toggleCamera(),
    );
  }
}
