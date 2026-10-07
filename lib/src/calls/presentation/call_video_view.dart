import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Plays [stream]'s video, filling the space it gets. Owns the renderer
/// the plugin draws into.
class CallVideoView extends StatefulWidget {
  const CallVideoView({required this.stream, this.mirror = false, super.key});

  final MediaStream stream;

  /// Shows the video mirrored, as people expect of their own front camera.
  final bool mirror;

  @override
  State<CallVideoView> createState() => _CallVideoViewState();
}

class _CallVideoViewState extends State<CallVideoView> {
  final _renderer = RTCVideoRenderer();
  var _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _renderer.initialize();
    } on Object {
      // No video then, e.g. without the plugin in widget tests; the call
      // itself goes on.
      return;
    }
    if (!mounted) {
      return;
    }
    _renderer.srcObject = widget.stream;
    setState(() => _ready = true);
  }

  @override
  void didUpdateWidget(CallVideoView old) {
    super.didUpdateWidget(old);
    if (_ready && old.stream != widget.stream) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    unawaited(_renderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.expand();
    }
    return RTCVideoView(
      _renderer,
      mirror: widget.mirror,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
