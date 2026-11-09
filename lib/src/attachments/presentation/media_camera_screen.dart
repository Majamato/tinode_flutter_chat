import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/camera_capture.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/media_camera_mode_switch.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/media_camera_top_bar.dart';

/// The in-app camera: it takes a photo or records a video, with
/// its own switch between the two, and closes with what it took. A video
/// stops at [maxVideoDuration]. Always dark, with no app bar for the host
/// to restyle. Watches nothing; CamerAwesome drives it.
class MediaCameraScreen extends StatefulWidget {
  const MediaCameraScreen({required this.maxVideoDuration, super.key});

  /// Opens the camera; what it took, or null when it was closed.
  static Future<CameraCapture?> open(
    BuildContext context, {
    required Duration maxVideoDuration,
  }) => Navigator.of(context).push(
    MaterialPageRoute<CameraCapture>(
      builder: (_) => MediaCameraScreen(maxVideoDuration: maxVideoDuration),
    ),
  );

  /// How long a video may record: what fits the size limit.
  final Duration maxVideoDuration;

  @override
  State<MediaCameraScreen> createState() => _MediaCameraScreenState();
}

class _MediaCameraScreenState extends State<MediaCameraScreen> {
  var _done = false;

  /// Closes with the photo or video [capture] saved, once.
  void _onCapture(MediaCapture capture) {
    if (_done || capture.status != MediaCaptureStatus.success) {
      return;
    }
    final path = capture.captureRequest.path;
    if (path == null) {
      return;
    }
    _done = true;
    Navigator.of(context).pop(CameraCapture(path, isVideo: !capture.isPicture));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
        enablePhysicalButton: true,
        saveConfig: SaveConfig.photoAndVideo(
          exifPreferences: ExifPreferences(saveGPSLocation: false),
          videoOptions: VideoOptions(
            enableAudio: true,
            quality: VideoRecordingQuality.hd,
            android: AndroidVideoOptions(
              fallbackStrategy: QualityFallbackStrategy.lower,
            ),
            ios: CupertinoVideoOptions(fileType: CupertinoFileType.mpeg4),
          ),
        ),
        progressIndicator: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        topActionsBuilder: (state) => MediaCameraTopBar(
          state: state,
          maxVideoDuration: widget.maxVideoDuration,
        ),
        middleContentBuilder: (state) => Column(
          children: [
            const Spacer(),
            MediaCameraModeSwitch(state: state),
          ],
        ),
        onMediaCaptureEvent: _onCapture,
      ),
    );
  }
}
