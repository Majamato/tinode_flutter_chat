import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/presence_visibility_controller.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_tile.dart';

/// "Show my online status", with a switch; the row toggles it too. Off
/// while the profile can't be read or the change is being saved; a failed
/// save says why. Watches the user's choice and the save.
class PresenceTile extends ConsumerWidget {
  const PresenceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    final shown = ref.watch(myPresenceShownProvider);
    final saving = ref.watch(
      presenceVisibilityControllerProvider.select((s) => s.isLoading),
    );
    final enabled = shown != null && !saving;

    Future<void> set({required bool shown}) async {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final controller = ref.read(
        presenceVisibilityControllerProvider.notifier,
      );
      if (await controller.set(shown: shown)) {
        return;
      }
      final error = ref.read(presenceVisibilityControllerProvider).error;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            failureMessage(
              strings,
              error == null ? ChatFailure.unexpected : ChatFailure.of(error),
            ),
          ),
        ),
      );
    }

    return MergeSemantics(
      child: SettingsTile(
        icon: TinodeChatIcons.of(context).onlineStatus,
        title: strings.showMyOnlineStatus,
        onTap: enabled ? () => set(shown: !shown) : null,
        trailing: Switch.adaptive(
          value: shown ?? true,
          onChanged: enabled ? (value) => set(shown: value) : null,
        ),
      ),
    );
  }
}
