import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_photo_controller.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeAttachmentPicker picker;
  late ProviderContainer container;

  setUp(() async {
    picker = FakeAttachmentPicker();
    container =
        await loggedInContainer(FakeTinodeSession(), attachmentPicker: picker)
          ..listen(newGroupPhotoControllerProvider, (_, _) {});
  });

  NewGroupPhotoController controller() =>
      container.read(newGroupPhotoControllerProvider.notifier);

  test('a picked image is kept with its bytes, not uploaded', () async {
    picker.next = pickedFile(
      'me.png',
      [1, 2, 3],
      mimeType: 'image/png',
      isImage: true,
    );
    await controller().pick(AttachmentSource.camera);
    final photo = container.read(newGroupPhotoControllerProvider).value;
    expect(photo?.file.name, 'me.png');
    expect(photo?.preview, [1, 2, 3]);
    expect(picker.picks, [AttachmentSource.camera]);
  });

  test('cancelling keeps the photo already picked', () async {
    picker.next = pickedFile(
      'a.png',
      [1],
      mimeType: 'image/png',
      isImage: true,
    );
    await controller().pick(AttachmentSource.gallery);
    await controller().pick(AttachmentSource.gallery);
    expect(
      container.read(newGroupPhotoControllerProvider).value?.file.name,
      'a.png',
    );
  });

  test('a file that is no image is ignored', () async {
    picker.next = pickedFile('a.pdf', [1], mimeType: 'application/pdf');
    await controller().pick(AttachmentSource.gallery);
    expect(container.read(newGroupPhotoControllerProvider).value, isNull);
  });

  test('a broken picker is an error', () async {
    picker.failWith = Exception('broken');
    await controller().pick(AttachmentSource.gallery);
    expect(
      container.read(newGroupPhotoControllerProvider),
      isA<AsyncError<Object?>>(),
    );
  });
}
