import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';

void main() {
  late ImagePickerPlatform before;

  setUp(() => before = ImagePickerPlatform.instance);
  tearDown(() => ImagePickerPlatform.instance = before);

  test('on Android, photos and videos come from the photo picker', () {
    final android = ImagePickerAndroid();
    ImagePickerPlatform.instance = android;
    expect(android.useAndroidPhotoPicker, isFalse);

    PluginAttachmentPicker();

    expect(android.useAndroidPhotoPicker, isTrue);
  });
}
