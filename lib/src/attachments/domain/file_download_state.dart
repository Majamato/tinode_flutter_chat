import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Where fetching a file to open it stands.
sealed class FileDownloadState with ValueObject {
  const FileDownloadState();
}

/// Not fetched in this screen yet; it may be cached already.
final class DownloadIdle extends FileDownloadState {
  const DownloadIdle();

  @override
  List<Object?> get props => const [];
}

/// On its way: [received] of [total] bytes, [total] null when unknown.
final class Downloading extends FileDownloadState {
  const Downloading(this.received, this.total);

  final int received;
  final int? total;

  /// From 0 to 1; null when the total is unknown.
  double? get fraction => switch (total) {
    final total? when total > 0 => (received / total).clamp(0, 1),
    _ => null,
  };

  @override
  List<Object?> get props => [received, total];
}

/// On this device, ready to open.
final class Downloaded extends FileDownloadState {
  const Downloaded(this.file);

  final LocalFile file;

  @override
  List<Object?> get props => [file];
}

final class DownloadFailed extends FileDownloadState {
  const DownloadFailed(this.failure);

  final ChatFailure failure;

  @override
  List<Object?> get props => [failure];
}
