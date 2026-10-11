import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_form.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';

/// Progress, error, or the profile once read. Rebuilds only when that
/// changes, not when the profile is saved.
class ProfileBody extends ConsumerWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (loaded, error) = ref.watch(
      profileControllerProvider.select((s) => (s.hasValue, s.error)),
    );
    if (loaded) {
      return const ProfileForm();
    }
    if (error != null) {
      return ErrorRetryView(
        failure: ChatFailure.of(error),
        onRetry: ref.read(profileControllerProvider.notifier).reload,
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
