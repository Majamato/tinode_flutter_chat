import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_token_controller.g.dart';

/// The host's push token for this device, e.g. from Firebase Cloud
/// Messaging; null while it has none. `PushRegistration` sends it to the
/// server.
@Riverpod(keepAlive: true)
class PushTokenController extends _$PushTokenController {
  @override
  String? build() => null;

  /// Replaces the token, e.g. after the push service renewed it.
  // A setter would hide that this notifies the registration.
  // ignore: use_setters_to_change_properties
  void set(String? token) => state = token;
}
