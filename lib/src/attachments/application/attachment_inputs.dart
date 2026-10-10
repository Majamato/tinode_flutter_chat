import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/io_file_store.dart';

part 'attachment_inputs.g.dart';

/// Where each user's downloaded and staged files live; tests override it
/// with memory.
@Riverpod(keepAlive: true)
FileStoreOpener fileStoreOpener(Ref ref) => DeviceFileStoreOpener();

/// How a downloaded file is opened; tests override it with a fake.
@Riverpod(keepAlive: true)
FileOpener fileOpener(Ref ref) => openWithSystem;

/// How the user picks photos and files; tests override it with a fake.
@Riverpod(keepAlive: true)
AttachmentPicker attachmentPicker(Ref ref) => PluginAttachmentPicker();

/// Whether the attach menu offers the camera.
@Riverpod(keepAlive: true)
bool cameraAvailable(Ref ref) => ref.watch(attachmentPickerProvider).hasCamera;
