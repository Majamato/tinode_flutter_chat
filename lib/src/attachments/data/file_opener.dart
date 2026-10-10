import 'package:open_filex/open_filex.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// Hands [file] to the system's viewer for its type; false when nothing on
/// the device opens it. Tests pass a fake.
typedef FileOpener = Future<bool> Function(LocalFile file, {String? mimeType});

/// A [FileOpener] over `open_filex`.
Future<bool> openWithSystem(LocalFile file, {String? mimeType}) async {
  final path = file.path;
  if (path == null) {
    return false;
  }
  final result = await OpenFilex.open(path, type: mimeType);
  return result.type == ResultType.done;
}
