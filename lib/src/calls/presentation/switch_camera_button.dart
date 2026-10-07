import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_control_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Swaps the front and back cameras; watches nothing.
class SwitchCameraButton extends ConsumerWidget {
  const SwitchCameraButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CallControlButton(
    icon: Icons.cameraswitch,
    tooltip: TinodeChatStrings.of(context).switchCamera,
    onPressed: () =>
        unawaited(ref.read(callControllerProvider.notifier).switchCamera()),
  );
}
