import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/account/application/change_password_controller.dart';
import 'package:tinode_flutter_chat/src/account/application/delete_account_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_photo_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_save_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late FakeAttachmentPicker picker;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession()
      ..profile = const Profile(
        name: 'Alice',
        note: 'Hi',
        raw: {
          'fn': 'Alice',
          'note': 'Hi',
          'org': {'fn': 'Acme'},
        },
      );
    picker = FakeAttachmentPicker();
    container = await loggedInContainer(session, attachmentPicker: picker)
      ..listen(profileControllerProvider, (_, _) {})
      ..listen(profileSaveControllerProvider, (_, _) {})
      ..listen(profilePhotoControllerProvider, (_, _) {})
      ..listen(changePasswordControllerProvider, (_, _) {})
      ..listen(deleteAccountControllerProvider, (_, _) {});
  });

  test('the profile comes from me', () async {
    final profile = await container.read(profileControllerProvider.future);
    expect(
      (profile.name, profile.note, profile.initials),
      ('Alice', 'Hi', 'A'),
    );
    expect(session.calls, contains('description me'));
  });

  test('offline the profile fails with a lost connection', () async {
    session.dropConnection();
    container.invalidate(profileControllerProvider);
    await expectLater(
      container.read(profileControllerProvider.future),
      throwsA(isA<ConnectionLostException>()),
    );
  });

  test('saving the name keeps the rest of the profile, the note included', () async {
    await container.read(profileControllerProvider.future);

    final saved = await container
        .read(profileSaveControllerProvider.notifier)
        .save(name: ' Alicia ');

    expect(saved, isTrue);
    expect(session.profile?.toJson(), {
      'fn': 'Alicia',
      'note': 'Hi',
      'org': {'fn': 'Acme'},
    });
    expect(container.read(profileControllerProvider).value?.name, 'Alicia');
  });

  test('a refused save shows why', () async {
    await container.read(profileControllerProvider.future);
    session.failUpdateProfile = const ServerException(403, 'forbidden');

    final saved = await container
        .read(profileSaveControllerProvider.notifier)
        .save(name: 'Alicia');

    expect(saved, isFalse);
    expect(container.read(profileSaveFailureProvider), ChatFailure.rejected);
  });

  test('a new photo is uploaded and set by ref', () async {
    await container.read(profileControllerProvider.future);
    picker.next = pickedFile(
      'me.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );

    await container
        .read(profilePhotoControllerProvider.notifier)
        .change(AttachmentSource.camera);

    expect(picker.picks, [AttachmentSource.camera]);
    expect(session.calls, contains('upload me.png'));
    final photo = session.profile?.photo;
    expect(photo?.type, 'png');
    expect(photo?.ref, startsWith('/v0/file/s/fake'));
    expect(
      container.read(profileControllerProvider).value?.photo?.ref,
      photo?.ref,
    );
  });

  test('cancelling the picker changes nothing', () async {
    await container.read(profileControllerProvider.future);

    await container
        .read(profilePhotoControllerProvider.notifier)
        .change(AttachmentSource.gallery);

    expect(session.calls, isNot(contains(startsWith('upload'))));
    expect(container.read(profilePhotoControllerProvider).hasError, isFalse);
  });

  test('changing the password keeps the login', () async {
    await container
        .read(changePasswordControllerProvider.notifier)
        .submit(password: 'new-pw');

    expect((session.changedPassword, session.changedLogin), ('new-pw', null));
    expect(session.calls, contains('changePassword'));
    expect(container.read(changePasswordControllerProvider).value, isTrue);
  });

  test('a failed password change shows why', () async {
    session.failChangePassword = const ConnectionLostException();

    await container
        .read(changePasswordControllerProvider.notifier)
        .submit(password: 'new-pw');

    expect(session.changedPassword, isNull);
    expect(
      container.read(changePasswordFailureProvider),
      ChatFailure.connectionLost,
    );
  });

  test('deleting the account ends the session', () async {
    await container.read(deleteAccountControllerProvider.notifier).delete();
    final state = await container.read(sessionControllerProvider.future);

    expect(session.accountDeleted, isTrue);
    expect(state, isA<SessionAwaitingLogin>());
  });
}
