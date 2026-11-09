import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What an outgoing attachment is going through before its message goes.
enum AttachmentPhase {
  /// Shrunk on this device: a photo scaled down, a video re-encoded.
  compressing,

  /// Sent to the server.
  uploading,
}

/// How far an outgoing attachment got in its [phase]: [fraction] from 0 to
/// 1, null when unknown (a photo's compression reports none).
final class AttachmentProgress with ValueObject {
  const AttachmentProgress(this.phase, [this.fraction]);

  /// What to show for an attachment still to [compress] (else to upload)
  /// given what was [reported]: a report of the other phase is stale, and
  /// nothing reported yet is the phase's start, of unknown progress.
  factory AttachmentProgress.shown(
    AttachmentProgress? reported, {
    required bool compress,
  }) {
    final phase = compress
        ? AttachmentPhase.compressing
        : AttachmentPhase.uploading;
    return reported?.phase == phase ? reported! : AttachmentProgress(phase);
  }

  final AttachmentPhase phase;
  final double? fraction;

  /// [fraction] as a whole percentage; null when unknown.
  int? get percent => switch (fraction) {
    final f? => (f.clamp(0, 1) * 100).floor(),
    null => null,
  };

  @override
  List<Object?> get props => [phase, fraction];
}
