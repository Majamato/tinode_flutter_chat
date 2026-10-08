import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_list.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/error_retry_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// What the [scope]'s search has: a hint, progress, an error, nothing
/// found, or the results. Watches the search's status and results.
class FindResults extends ConsumerWidget {
  const FindResults({
    required this.scope,
    required this.onSelected,
    this.selected,
    super.key,
  });

  final FindScope scope;
  final ValueChanged<SearchResult> onSelected;

  /// The topics picked so far, when results can be picked; see
  /// [SearchResultList.selected].
  final Set<String>? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, failure, results) = ref.watch(
      findControllerProvider(
        scope,
      ).select((s) => (s.status, s.failure, s.results)),
    );
    final strings = TinodeChatStrings.of(context);

    return switch ((status, results.isEmpty)) {
      (FindStatus.failed, _) => ErrorRetryView(
        failure: failure ?? ChatFailure.unexpected,
        onRetry: ref.read(findControllerProvider(scope).notifier).retry,
      ),
      (FindStatus.idle, _) => _Message(strings.findHint),
      (FindStatus.searching, true) => const Center(
        child: CircularProgressIndicator(),
      ),
      (FindStatus.done, true) => _Message(strings.nobodyFound),
      (_, false) => SearchResultList(
        results: results,
        searching: status == FindStatus.searching,
        selected: selected,
        onSelected: onSelected,
      ),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
