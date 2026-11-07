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

/// The user's own profile.
final class TinodeProfileScreen extends TinodeScreen {
  /// The profile screen.
  const TinodeProfileScreen();
}

/// Changing the password.
final class TinodeChangePasswordScreen extends TinodeScreen {
  /// The password change screen.
  const TinodeChangePasswordScreen();
}

/// Finding people and groups to chat with.
final class TinodeFindPeopleScreen extends TinodeScreen {
  /// The search for people and groups.
  const TinodeFindPeopleScreen();
}

/// Creating a group.
final class TinodeNewGroupScreen extends TinodeScreen {
  /// The new group screen.
  const TinodeNewGroupScreen();
}

/// A picked file, with its caption, before sending it.
final class TinodeAttachmentPreviewScreen extends TinodeScreen {
  /// The attachment preview screen.
  const TinodeAttachmentPreviewScreen();
}

/// An image full screen.
final class TinodeImageViewerScreen extends TinodeScreen {
  /// The image viewer.
  const TinodeImageViewerScreen();
}

/// Resetting a forgotten password, before logging in.
final class TinodePasswordResetScreen extends TinodeScreen {
  /// The password reset screen.
  const TinodePasswordResetScreen();
}

/// Confirming the user's email, before logging in.
final class TinodeConfirmEmailScreen extends TinodeScreen {
  /// The email confirmation screen.
  const TinodeConfirmEmailScreen();
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

/// About one chat: its members, and deleting or leaving it.
final class TinodeChatInfoScreen extends TinodeScreen {
  /// The info of the chat named [topic].
  const TinodeChatInfoScreen(this.topic);

  /// The chat's topic name.
  final String topic;

  @override
  List<Object?> get props => [topic];
}

/// The message search of one chat.
final class TinodeMessageSearchScreen extends TinodeScreen {
  /// The message search of the chat named [topic].
  const TinodeMessageSearchScreen(this.topic);

  /// The chat's topic name.
  final String topic;

  @override
  List<Object?> get props => [topic];
}
