import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Where the call stands, or how long it has lasted once connected.
/// Watches the stage, the connect time and the failure; ticks every second
/// while connected.
class CallStatusText extends ConsumerStatefulWidget {
  const CallStatusText({this.style, super.key});

  final TextStyle? style;

  @override
  ConsumerState<CallStatusText> createState() => _CallStatusTextState();
}

class _CallStatusTextState extends ConsumerState<CallStatusText> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (:stage, :connectedAt, :failure) = ref.watch(
      callControllerProvider.select(
        (c) =>
            (stage: c?.stage, connectedAt: c?.connectedAt, failure: c?.failure),
      ),
    );
    _tickWhile(running: connectedAt != null && stage == CallStage.connected);
    final strings = TinodeChatStrings.of(context);
    final text = switch (stage) {
      null => '',
      CallStage.preparing || CallStage.calling => strings.calling,
      CallStage.ringing => strings.ringing,
      CallStage.incoming => '',
      CallStage.connecting => strings.callConnecting,
      CallStage.connected => formatCallDuration(
        clock.now().difference(connectedAt ?? clock.now()),
      ),
      CallStage.ended =>
        failure == null
            ? strings.callEnded
            : callFailureMessage(strings, failure),
    };
    return Text(text, style: widget.style, textAlign: TextAlign.center);
  }

  void _tickWhile({required bool running}) {
    if (running && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }
}
