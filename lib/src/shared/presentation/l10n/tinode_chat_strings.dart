import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings_scope.dart';

/// Every text `TinodeChat` shows, in English by default.
///
/// Pass your own to `TinodeChat.strings` to translate or reword them:
///
/// ```dart
/// TinodeChat(
///   config: config,
///   strings: const TinodeChatStrings(chatListTitle: 'Conversaciones'),
/// )
/// ```
@immutable
class TinodeChatStrings {
  /// Creates the texts; any left out keep their English default.
  const TinodeChatStrings({
    this.chatListTitle = 'Chats',
    this.noChats = 'No chats yet',
    this.connecting = 'Connecting…',
    this.loginTitle = 'Sign in',
    this.loginField = 'Login',
    this.passwordField = 'Password',
    this.signIn = 'Sign in',
    this.retry = 'Retry',
    this.reconnect = 'Reconnect',
    this.reconnecting = 'Reconnecting…',
    this.messageHint = 'Message',
    this.send = 'Send',
    this.readOnly = 'Only admins can post here.',
    this.unreachable = 'Cannot reach the chat server.',
    this.connectionLost = 'The connection to the chat server was lost.',
    this.badCredentials = 'Wrong login or password.',
    this.timeout = 'The chat server did not answer in time.',
    this.rejected = 'The chat server refused the request.',
    this.unexpected = 'Something went wrong.',
  });

  /// The texts of the nearest `TinodeChat`, or the defaults outside one.
  factory TinodeChatStrings.of(BuildContext context) =>
      TinodeChatStringsScope.maybeOf(context) ?? const TinodeChatStrings();

  /// Title of the chat list screen.
  final String chatListTitle;

  /// Shown when the chat list is empty.
  final String noChats;

  /// Shown while connecting to the server.
  final String connecting;

  /// Title of the login screen.
  final String loginTitle;

  /// Label of the login name field.
  final String loginField;

  /// Label of the password field.
  final String passwordField;

  /// Label of the login button.
  final String signIn;

  /// Label of buttons that try a failed load again.
  final String retry;

  /// Label of the button that connects again after a failure.
  final String reconnect;

  /// Shown while the client restores a dropped connection by itself.
  final String reconnecting;

  /// Placeholder of the message field.
  final String messageHint;

  /// Tooltip of the send button.
  final String send;

  /// Shown instead of the message field where the user cannot post, e.g.
  /// to channel followers.
  final String readOnly;

  /// The server could not be reached.
  final String unreachable;

  /// An open connection dropped.
  final String connectionLost;

  /// The server rejected the login.
  final String badCredentials;

  /// A request got no answer in time.
  final String timeout;

  /// The server rejected a request.
  final String rejected;

  /// Any other error.
  final String unexpected;
}
