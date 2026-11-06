import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_auth_mode.dart';

/// What a `TinodeLoginBuilder` needs to draw the login screen: which side
/// it is on, and the working form for that side.
@immutable
class TinodeLoginView {
  const TinodeLoginView({
    required this.mode,
    required this.onModeChanged,
    required this.signUpOffered,
    required this.form,
  });

  /// Whether the user is signing in or up. Always
  /// [TinodeAuthMode.signIn] when [signUpOffered] is false.
  final TinodeAuthMode mode;

  /// Moves to the other side; call it from your own switch.
  final ValueChanged<TinodeAuthMode> onModeChanged;

  /// Whether the host and the server offer signing up, so a switch to it
  /// belongs on screen. See `TinodeChatFeatures.signUp`.
  final bool signUpOffered;

  /// The form for [mode], keyed by it: fields, errors, the button, the
  /// forgot password link and the sign-up terms. It logs in, signs up and
  /// asks for the mailed code on its own, and follows the app's theme. Put
  /// it anywhere in the builder's result, inside no other `Navigator`.
  final Widget form;
}
