import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/profile/domain/my_profile.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'profile_controller.g.dart';

/// The user's own profile, read from the server while the profile screen
/// is open. It needs the link: offline it fails with a lost connection.
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<MyProfile> build() async {
    final session = ref.watch(activeSessionProvider);
    if (session == null) {
      throw const ConnectionLostException();
    }
    final description = await session.description('me');
    return MyProfile(description?.public ?? const Profile());
  }

  /// This device saved [profile]: show it without asking the server.
  void saved(Profile profile) => state = AsyncData(MyProfile(profile));

  /// Reads the profile again, e.g. after a failure.
  void reload() => ref.invalidateSelf();
}
