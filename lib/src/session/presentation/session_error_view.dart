import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Shown when the session could not connect or lost its connection.
class SessionErrorView extends ConsumerWidget {
  const SessionErrorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = ref.watch(sessionFailureProvider);
    return Scaffold(
      body: ErrorRetryView(
        failure: failure ?? ChatFailure.unexpected,
        retryLabel: TinodeChatStrings.of(context).reconnect,
        onRetry: ref.read(sessionControllerProvider.notifier).reconnect,
      ),
    );
  }
}
