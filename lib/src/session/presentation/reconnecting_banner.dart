import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// A strip below the chats while the link is being restored; watches only
/// whether it is.
class ReconnectingBanner extends ConsumerWidget {
  const ReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(reconnectingControllerProvider)) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            TinodeChatStrings.of(context).reconnecting,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}
