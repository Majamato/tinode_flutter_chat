import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/member_search.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// The field under the add members bar: what the user types filters the
/// suggested members at once and searches the server. Watches nothing.
class MemberFindBar extends ConsumerWidget implements PreferredSizeWidget {
  const MemberFindBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(TinodeAppBar.rowHeight);

  void _filter(WidgetRef ref, String input) =>
      ref.read(memberFilterProvider.notifier).change(input);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassField(
      onPage: true,
      child: FindField(
        scope: FindScope.groupMembers,
        hint: TinodeChatStrings.of(context).memberFindHint,
        autofocus: false,
        onChanged: (input) => _filter(ref, input),
      ),
    );
  }
}
