import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A screen of the chat that has an app bar, as `TinodeChat.appBarBuilder`
/// sees it, to wrap or replace that bar.
///
/// ```dart
/// appBarBuilder: (context, screen, defaultAppBar) => switch (screen) {
///   TinodeChatScreen(:final topic) => MyChatBar(topic: topic),
///   _ => defaultAppBar,
/// },
/// ```
sealed class TinodeScreen with ValueObject {
  const TinodeScreen();

  @override
  List<Object?> get props => const [];
}

/// The chat list.
final class TinodeChatListScreen extends TinodeScreen {
  /// The chat list screen.
  const TinodeChatListScreen();
}

/// The calls history tab.
final class TinodeCallsScreen extends TinodeScreen {
  /// The calls history screen.
  const TinodeCallsScreen();
}

/// The settings tab.
final class TinodeSettingsScreen extends TinodeScreen {
  /// The settings screen.
  const TinodeSettingsScreen();
}

/// The appearance screen: palettes and light or dark.
final class TinodeAppearanceScreen extends TinodeScreen {
  /// The appearance screen.
  const TinodeAppearanceScreen();
}

/// The account screen: changing the password, logging out and deleting
/// the account.
final class TinodeAccountScreen extends TinodeScreen {
  /// The account screen.
  const TinodeAccountScreen();
}

/// One open chat.
final class TinodeChatScreen extends TinodeScreen {
  /// The screen of the chat named [topic].
  const TinodeChatScreen(this.topic);

  /// The chat's topic name.
  final String topic;

  @override
  List<Object?> get props => [topic];
}
