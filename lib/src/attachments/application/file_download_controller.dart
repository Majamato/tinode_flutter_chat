import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/file_download_state.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/progress_throttle.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'file_download_controller.g.dart';

/// Opening a received file: its download progress, then the file. Only
/// the file's bubble watches it.
@riverpod
class FileDownloadController extends _$FileDownloadController {
  @override
  FileDownloadState build(String fileRef) => const DownloadIdle();

  /// Downloads the file unless this device has it, then opens it with the
  /// system's viewer. Returns false when nothing could open it, and null
  /// when it could not be fetched (the state says why) or is on its way.
  Future<bool?> open({String? mimeType}) async {
    if (state is Downloading) {
      return null;
    }
    final session = ref.read(activeSessionProvider);
    if (session == null) {
      state = const DownloadFailed(ChatFailure.connectionLost);
      return null;
    }
    state = const Downloading(0, null);
    final throttle = ProgressThrottle();
    try {
      final file = await session.fetchFile(
        fileRef,
        onProgress: (received, total) {
          if (ref.mounted && throttle.admit(received, total, clock.now())) {
            state = Downloading(received, total);
          }
        },
      );
      if (!ref.mounted) {
        return null;
      }
      state = Downloaded(file);
      return await ref.read(fileOpenerProvider)(file, mimeType: mimeType);
    } on Object catch (e) {
      if (ref.mounted) {
        state = DownloadFailed(ChatFailure.of(e));
      }
      return null;
    }
  }
}
