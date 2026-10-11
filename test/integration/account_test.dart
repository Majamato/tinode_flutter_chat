@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_actions_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_exit.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/profile/application/change_password_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_save_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import 'group_chat_test.dart' show config, eventually;

// Runs against ../tinode-tests:
//   flutter test --tags integration --run-skipped --concurrency=1
// Each test signs up its own users and deletes them at the end.

/// A login no earlier run used.
String uniqueLogin(String prefix) =>
    '$prefix${DateTime.now().microsecondsSinceEpoch % 10000000000}';

/// A container on the login screen, as an app without credentials starts.
Future<ProviderContainer> loggedOut() async {
  final container = createTinodeContainer(
    config: config,
    storeOpener: MemoryChatStoreOpener(),
  );
  addTearDown(container.dispose);
  container.listen(sessionControllerProvider, (_, _) {});
  expect(
    await container.read(sessionControllerProvider.future),
    isA<SessionAwaitingLogin>(),
  );
  return container;
}

/// Signs up a new user named [name] through the session; their account is
/// deleted when the test ends, unless the test did it.
Future<(ProviderContainer, String login, String userId)> signUp(
  String name,
) async {
  final container = await loggedOut();
  final login = uniqueLogin(name.toLowerCase());
  await container
      .read(sessionControllerProvider.notifier)
      .signUp(login: login, password: 'secret1', name: name);
  container.listen(chatListControllerProvider, (_, _) {});
  addTearDown(() async {
    if (container.read(sessionControllerProvider).value is SessionLoggedIn) {
      await container.read(sessionControllerProvider.notifier).deleteAccount();
    }
  });
  return (container, login, container.read(currentUserIdProvider)!);
}

void main() {
  test('sign up, edit the profile, change the password, delete', () async {
    final (user, login, _) = await signUp('Probe');

    user
      ..listen(profileControllerProvider, (_, _) {})
      ..listen(profileSaveControllerProvider, (_, _) {})
      ..listen(changePasswordControllerProvider, (_, _) {});
    expect((await user.read(profileControllerProvider.future)).name, 'Probe');

    expect(
      await user
          .read(profileSaveControllerProvider.notifier)
          .save(name: 'Probe Renamed', note: 'From the tests'),
      isTrue,
    );
    user.invalidate(profileControllerProvider);
    final profile = await user.read(profileControllerProvider.future);
    expect((profile.name, profile.note), ('Probe Renamed', 'From the tests'));

    await user
        .read(changePasswordControllerProvider.notifier)
        .submit(password: 'secret2');
    expect(user.read(changePasswordControllerProvider).value, isTrue);

    final again = createTinodeContainer(
      config: config,
      credentials: TinodeCredentials.password(login, 'secret2'),
      storeOpener: MemoryChatStoreOpener(),
    );
    addTearDown(again.dispose);
    again.listen(sessionControllerProvider, (_, _) {});
    expect(
      await again.read(sessionControllerProvider.future),
      isA<SessionLoggedIn>(),
    );

    await user.read(sessionControllerProvider.notifier).deleteAccount();
    expect(
      await user.read(sessionControllerProvider.future),
      isA<SessionAwaitingLogin>(),
    );
  });

  test('a taken login is refused at sign-up', () async {
    final container = await loggedOut();
    await expectLater(
      container
          .read(sessionControllerProvider.notifier)
          .signUp(login: 'alice', password: 'secret1', name: 'Not Alice'),
      throwsA(
        isA<ServerException>().having(
          ChatFailure.ofAccount,
          'failure',
          ChatFailure.loginTaken,
        ),
      ),
    );
  });

  test('a deleted group vanishes for its member', () async {
    final (owner, _, _) = await signUp('Owner');
    final (member, _, memberId) = await signUp('Member');

    final session = owner.read(activeSessionProvider)!;
    final group = await session.createGroup(
      public: const Profile(name: 'Doomed'),
    );
    await session.addMember(group, memberId);
    await session.detach(group);
    await eventually(
      'the member sees the group',
      () => member.read(chatListControllerProvider).contains(group),
    );
    owner.read(chatListControllerProvider.notifier).refresh();
    await eventually(
      'the owner sees the group',
      () => owner.read(chatListControllerProvider).contains(group),
    );
    member.listen(chatControllerProvider(group), (_, _) {});

    owner.listen(chatActionsControllerProvider(group), (_, _) {});
    expect(owner.read(chatExitProvider(group)), ChatExit.deleteGroup);
    expect(
      await owner
          .read(chatActionsControllerProvider(group).notifier)
          .exit(ChatExit.deleteGroup),
      isTrue,
    );

    await eventually(
      'the group leaves the member list',
      () => !member.read(chatListControllerProvider).contains(group),
    );
    expect(
      member.read(chatControllerProvider(group)).failure,
      ChatFailure.gone,
    );
  });
}
