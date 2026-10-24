import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_minimized.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_failure_message.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/incoming_call_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The call, over every chat route: the ringing screen, the call screen,
/// or nothing, also while the call is minimized to the call bar. It sits
/// above the chat navigator, so it reacts whatever route is open. Watches
/// only whether there is a call, whether it is ringing and whether it is
/// minimized; reports a failed call in a snack bar.
class CallLayer extends ConsumerWidget {
  const CallLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(callControllerProvider.select((c) => c?.failure), (_, failure) {
      if (failure != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              callFailureMessage(TinodeChatStrings.of(context), failure),
            ),
          ),
        );
      }
    });
    final ringing = ref.watch(
      callControllerProvider.select(
        (c) => c == null ? null : c.stage == CallStage.incoming,
      ),
    );
    final minimized = ref.watch(callMinimizedProvider);
    return switch (ringing) {
      null => const SizedBox.shrink(),
      false when minimized => const SizedBox.shrink(),
      true => const Positioned.fill(child: IncomingCallView()),
      false => const Positioned.fill(child: CallView()),
    };
  }
}
