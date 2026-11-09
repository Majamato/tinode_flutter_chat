import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The camera's top row: close, and the flash; while a video records, how
/// long it has recorded against [maxVideoDuration], stopping it there.
class MediaCameraTopBar extends StatefulWidget {
  const MediaCameraTopBar({
    required this.state,
    required this.maxVideoDuration,
    super.key,
  });

  final CameraState state;
  final Duration maxVideoDuration;

  @override
  State<MediaCameraTopBar> createState() => _MediaCameraTopBarState();
}

class _MediaCameraTopBarState extends State<MediaCameraTopBar> {
  Timer? _ticker;
  Duration _recorded = Duration.zero;

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didUpdateWidget(MediaCameraTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _follow();
    }
  }

  /// Counts while a video records; stops it at the limit.
  void _follow() {
    final recording = widget.state is VideoRecordingCameraState;
    if (!recording) {
      _ticker?.cancel();
      _ticker = null;
      _recorded = Duration.zero;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recorded += const Duration(seconds: 1));
      final state = widget.state;
      if (_recorded >= widget.maxVideoDuration &&
          state is VideoRecordingCameraState) {
        _ticker?.cancel();
        unawaited(state.stopRecording());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final recording = state is VideoRecordingCameraState;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: TinodeChatStrings.of(context).closeCamera,
            icon: Icon(TinodeChatIcons.of(context).close),
            color: Colors.white,
            onPressed: recording ? null : () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          if (recording)
            PhotoTimeChip(
              child: Text(
                '${formatCallDuration(_recorded)} / '
                '${formatCallDuration(widget.maxVideoDuration)}',
                style: const TextStyle(
                  color: PhotoTimeChip.footerColor,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            )
          else
            AwesomeFlashButton(state: state),
        ],
      ),
    );
  }
}
