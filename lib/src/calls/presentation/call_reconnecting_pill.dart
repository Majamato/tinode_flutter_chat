import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A pill that says the call's link dropped and is coming back; it fades
/// in and out with it. Watches only whether the link is reconnecting.
class CallReconnectingPill extends ConsumerWidget {
  const CallReconnectingPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconnecting = ref.watch(
      callControllerProvider.select((c) => c?.reconnecting ?? false),
    );
    final theme = TinodeChatTheme.of(context);
    return AnimatedSwitcher(
      duration: theme.fadeDuration,
      child: reconnecting
          ? Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: theme.callControlColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TinodeChatIcons.of(context).offline,
                      size: 16,
                      color: theme.onCallColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      TinodeChatStrings.of(context).callReconnecting,
                      style: TextStyle(
                        color: theme.onCallColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
