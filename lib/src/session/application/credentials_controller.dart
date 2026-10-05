import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

part 'credentials_controller.g.dart';

/// The credentials a (re)connect logs in with. After a successful login it
/// holds the session token, so a reconnect never needs the password again.
@Riverpod(keepAlive: true)
class CredentialsController extends _$CredentialsController {
  @override
  TinodeCredentials? build() => ref.watch(initialCredentialsProvider);

  /// Replaces the credentials, e.g. with the token of a fresh login.
  // A setter would hide that this notifies the session's listeners.
  // ignore: use_setters_to_change_properties
  void remember(TinodeCredentials credentials) => state = credentials;

  void forget() => state = null;
}
