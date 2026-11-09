import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/gallery_saver.dart';
import 'package:tinode_flutter_chat/src/attachments/data/io_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/media_compressor.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';

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

/// How photos and videos shrink before they are sent; null where the
/// encoders aren't (desktops), and they go as picked. Tests override it
/// with a fake.
@Riverpod(keepAlive: true)
MediaCompressor? mediaCompressor(Ref ref) =>
    Platform.isAndroid || Platform.isIOS ? PluginMediaCompressor() : null;

/// Where the in-app camera's captures are saved; tests override it with a
/// fake.
@Riverpod(keepAlive: true)
GallerySaver gallerySaver(Ref ref) => saveToGallery;

/// How photos and videos shrink, and how large a video may be;
/// `createTinodeContainer` overrides it with the host's.
@Riverpod(keepAlive: true)
TinodeAttachmentLimits tinodeAttachmentLimits(Ref ref) =>
    const TinodeAttachmentLimits();

/// Whether the attach menu offers the camera.
@Riverpod(keepAlive: true)
bool cameraAvailable(Ref ref) => ref.watch(attachmentPickerProvider).hasCamera;
