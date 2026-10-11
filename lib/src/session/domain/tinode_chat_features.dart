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

/// Which account features `TinodeChat` offers, for servers that don't
/// support them all, e.g. one whose accounts an admin creates.
final class TinodeChatFeatures with ValueObject {
  /// Creates the switches; by default users can sign up, and reset their
  /// password where the server sends email.
  const TinodeChatFeatures({
    this.signUp = true,
    this.passwordReset = PasswordResetMode.automatic,
  });

  /// Whether the login screen offers to create an account.
  final bool signUp;

  /// When the login screen offers to reset a forgotten password.
  final PasswordResetMode passwordReset;

  /// Whether to offer the password reset, given the credentials the
  /// server requires at sign-up, e.g. `email`.
  bool offersPasswordReset(List<String> requiredCredentials) =>
      switch (passwordReset) {
        PasswordResetMode.automatic => requiredCredentials.contains('email'),
        PasswordResetMode.always => true,
        PasswordResetMode.never => false,
      };

  @override
  List<Object?> get props => [signUp, passwordReset];
}
