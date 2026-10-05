import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Provides the host's [TinodeChatStrings] to the chat's widgets.
class TinodeChatStringsScope extends InheritedWidget {
  const TinodeChatStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final TinodeChatStrings strings;

  static TinodeChatStrings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TinodeChatStringsScope>()
      ?.strings;

  @override
  bool updateShouldNotify(TinodeChatStringsScope oldWidget) =>
      strings != oldWidget.strings;
}
