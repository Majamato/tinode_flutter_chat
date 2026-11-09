import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The camera's switch between taking photos and recording videos, in the
/// chat's words; hidden while a video records.
class MediaCameraModeSwitch extends StatelessWidget {
  const MediaCameraModeSwitch({required this.state, super.key});

  final CameraState state;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    if (state is VideoRecordingCameraState ||
        state is PreparingCameraState ||
        state.captureMode == null) {
      return const SizedBox(height: 48);
    }
    final strings = TinodeChatStrings.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (mode, label) in [
            (CaptureMode.photo, strings.cameraPhoto),
            (CaptureMode.video, strings.cameraVideo),
          ])
            TextButton(
              onPressed: state.captureMode == mode
                  ? null
                  : () => state.setState(mode),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.amberAccent,
              ),
              child: Text(label.toUpperCase()),
            ),
        ],
      ),
    );
  }
}
