import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// When the login screen offers to reset a forgotten password.
enum PasswordResetMode {
  /// Only where the server requires an email at sign-up. A server that
  /// does so sends email, so the reset code can reach the user; Tinode
  /// v0.25 also fails on resets where email is optional.
  automatic,

  /// Always, e.g. for a server you know sends reset email.
  always,

  /// Never.
  never,
}

/// Which features `TinodeChat` offers, for servers that don't support them
/// all, e.g. one whose accounts an admin creates, or apps that can't use
/// them.
final class TinodeChatFeatures with ValueObject {
  /// Creates the switches; by default users can sign up, reset their
  /// password where the server sends email, make voice and video calls,
  /// record voice messages, see who is online and when they were last
  /// seen, and calls use the phone's own call screens.
  const TinodeChatFeatures({
    this.signUp = true,
    this.passwordReset = PasswordResetMode.automatic,
    this.voiceCalls = true,
    this.videoCalls = true,
    this.systemCalls = true,
    this.voiceMessages = true,
    this.presence = true,
  });

  /// Whether the login screen offers to create an account.
  final bool signUp;

  /// When the login screen offers to reset a forgotten password.
  final PasswordResetMode passwordReset;

  /// Whether users can place voice calls, and whether voice calls ring.
  /// When off, an incoming voice call is left to the user's other devices.
  final bool voiceCalls;

  /// Whether users can place video calls, and whether video calls ring.
  /// When off, an incoming video call is left to the user's other devices.
  final bool videoCalls;

  /// Whether calls go through the phone's own call screens: CallKit on
  /// iOS, a self-managed Telecom connection on Android. They ring over the
  /// lock screen and keep the microphone and camera while the app is in
  /// the background. Turn it off where CallKit isn't allowed, such as the
  /// App Store in China: calls then ring only inside the app.
  final bool systemCalls;

  /// Whether the composer records voice messages: the mic sits in the
  /// send button while the field is empty. Received voice messages play
  /// either way.
  final bool voiceMessages;

  /// Whether the chat shows who is online and when they were last seen.
  /// When off, presence from the server (`online`, `seen`, `pres on` /
  /// `off`) is dropped as it arrives and never kept. The server still sends
  /// it. It doesn't change what others see of this user: that is the
  /// user's own "Show my online status", in the settings.
  final bool presence;

  /// Whether calls of this kind, voice when [audioOnly], are on.
  bool allowsCall({required bool audioOnly}) =>
      audioOnly ? voiceCalls : videoCalls;

  /// Whether to offer the password reset, given the credentials the
  /// server requires at sign-up, e.g. `email`.
  bool offersPasswordReset(List<String> requiredCredentials) =>
      switch (passwordReset) {
        PasswordResetMode.automatic => requiredCredentials.contains('email'),
        PasswordResetMode.always => true,
        PasswordResetMode.never => false,
      };

  @override
  List<Object?> get props => [
    signUp,
    passwordReset,
    voiceCalls,
    videoCalls,
    systemCalls,
    voiceMessages,
    presence,
  ];
}
