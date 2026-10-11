import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_text.dart';

/// Why the last sign-up failed, if it did.
class SignUpErrorText extends ConsumerWidget {
  const SignUpErrorText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FailureText(failure: ref.watch(signUpFailureProvider));
}
