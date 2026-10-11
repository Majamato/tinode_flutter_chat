import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/delete_account_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/confirm_dialog.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Deletes the account, after asking. Success shows the login screen;
/// a failure shows in a snack bar. Watches whether a deletion runs.
class DeleteAccountTile extends ConsumerWidget {
  const DeleteAccountTile({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final strings = TinodeChatStrings.of(context);
    final controller = ref.read(deleteAccountControllerProvider.notifier);
    final confirmed = await ConfirmDialog.ask(
      context,
      message: strings.deleteAccountConfirm,
      action: strings.deleteAccount,
    );
    if (confirmed) {
      await controller.delete();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(deleteAccountFailureProvider, (_, failure) {
      if (failure != null) {
        final strings = TinodeChatStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(strings, failure))),
        );
      }
    });
    final busy = ref.watch(
      deleteAccountControllerProvider.select((s) => s.isLoading),
    );
    final error = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(Icons.delete_forever_outlined, color: error),
      title: Text(
        TinodeChatStrings.of(context).deleteAccount,
        style: TextStyle(color: error),
      ),
      trailing: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      enabled: !busy,
      onTap: () => unawaited(_delete(context, ref)),
    );
  }
}
