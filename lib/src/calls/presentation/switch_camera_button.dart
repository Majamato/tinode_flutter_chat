import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_round_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Swaps the front and back cameras; its icon spins half a turn on each
/// tap. Watches only whether a swap is running, during which it ignores
/// taps.
class SwitchCameraButton extends ConsumerStatefulWidget {
  const SwitchCameraButton({this.size = 64, super.key});

  final double size;

  @override
  ConsumerState<SwitchCameraButton> createState() => _SwitchCameraButtonState();
}

class _SwitchCameraButtonState extends ConsumerState<SwitchCameraButton> {
  static const _spin = Duration(milliseconds: 500);

  var _turns = 0.0;

  @override
  Widget build(BuildContext context) {
    final switching = ref.watch(
      callControllerProvider.select((c) => c?.switchingCamera ?? false),
    );
    final still = MediaQuery.disableAnimationsOf(context);
    return CallRoundButton(
      icon: AnimatedRotation(
        turns: _turns,
        duration: still ? Duration.zero : _spin,
        curve: TinodeChatTheme.of(context).springCurve,
        child: Icon(TinodeChatIcons.of(context).switchCamera),
      ),
      tooltip: TinodeChatStrings.of(context).switchCamera,
      size: widget.size,
      onPressed: switching
          ? null
          : () {
              setState(() => _turns += 0.5);
              unawaited(
                ref.read(callControllerProvider.notifier).switchCamera(),
              );
            },
    );
  }
}
