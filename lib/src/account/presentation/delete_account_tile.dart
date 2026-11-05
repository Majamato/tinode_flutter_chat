import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/account/application/delete_account_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/confirm_dialog.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_tile.dart';

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
    return SettingsTile(
      icon: TinodeChatIcons.of(context).deleteForever,
      title: TinodeChatStrings.of(context).deleteAccount,
      destructive: true,
      trailing: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: busy ? null : () => unawaited(_delete(context, ref)),
    );
  }
}
