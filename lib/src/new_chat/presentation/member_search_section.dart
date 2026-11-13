import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/member_search.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/member_list_message.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/pickable_member_tile.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Who the server found for the typed query beyond the suggested members,
/// as a card under its heading. A sliver, empty until the query is long
/// enough to search; watching keeps the search alive meanwhile. Bones
/// while the first answer is on its way, a thin bar while a newer one is,
/// an error with a retry, or "nobody found" when neither the suggestions
/// nor the server have anyone. Watches the search.
class MemberSearchSection extends ConsumerWidget {
  const MemberSearchSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(memberSearchProvider);
    final strings = TinodeChatStrings.of(context);
    final found = search.found;
    return switch ((search.status, found.isEmpty)) {
      (FindStatus.idle, _) => const SliverToBoxAdapter(),
      (FindStatus.failed, _) => SliverToBoxAdapter(
        child: ErrorRetryView(
          failure: search.failure ?? ChatFailure.unexpected,
          onRetry: ref
              .read(findControllerProvider(FindScope.groupMembers).notifier)
              .retry,
        ),
      ),
      (FindStatus.searching, true) => _Section(
        title: strings.moreMembers,
        sliver: const SliverToBoxAdapter(child: _Bones()),
      ),
      (FindStatus.done, true) => const _NobodyFound(),
      (_, false) => _Section(
        title: strings.moreMembers,
        searching: search.status == FindStatus.searching,
        sliver: SliverList.builder(
          itemCount: found.length,
          itemBuilder: (context, index) => PickableMemberTile(
            key: ValueKey(found[index].topic),
            result: found[index],
            first: index == 0,
            last: index == found.length - 1,
          ),
        ),
      ),
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.sliver,
    this.searching = false,
  });

  final String title;
  final Widget sliver;

  /// A newer answer is on its way: a thin bar over the rows.
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 22),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: SettingsLabel(title)),
          if (searching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ),
          sliver,
        ],
      ),
    );
  }
}

/// "Nobody found", unless some suggested member matches.
class _NobodyFound extends ConsumerWidget {
  const _NobodyFound();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anySuggested = ref.watch(
      memberSuggestionsProvider.select((s) => !s.isEmpty),
    );
    return SliverToBoxAdapter(
      child: anySuggested
          ? null
          : MemberListMessage(TinodeChatStrings.of(context).nobodyFound),
    );
  }
}

/// Three rows shaped like [PickableMemberTile]s, on their card.
class _Bones extends StatelessWidget {
  const _Bones();

  static const _names = [0.5, 0.36, 0.6];

  @override
  Widget build(BuildContext context) {
    final chat = TinodeChatTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chat.cardColor,
        borderRadius: BorderRadius.circular(chat.cardRadius),
      ),
      child: SkeletonShimmer(
        child: Column(
          children: [
            for (final name in _names)
              SizedBox(
                height: PickableMemberTile.height,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const SkeletonBone.circle(44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SkeletonBone.line(widthFactor: name, height: 14),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
