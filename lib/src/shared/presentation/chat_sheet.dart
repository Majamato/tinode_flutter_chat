import 'package:flutter/material.dart';

/// Opens the [ChatSheet] that [builder] returns as a Material 3 modal
/// bottom sheet with a drag handle: it dims the screen, closes on a tap
/// outside or a drag down, and completes with the value the sheet pops
/// with. The one way the chat opens a sheet.
Future<T?> showChatSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  builder: builder,
  showDragHandle: true,
  useSafeArea: true,
);

/// The content of a sheet opened by [showChatSheet]: an optional [title]
/// and [subtitle], then [children] (`ChatSheetAction` rows), which scroll
/// once the sheet is as tall as Material lets it be. Watches nothing.
class ChatSheet extends StatelessWidget {
  const ChatSheet({
    required this.children,
    this.title,
    this.subtitle,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final title?) _Header(title: title, subtitle: subtitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          if (subtitle case final subtitle?)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
