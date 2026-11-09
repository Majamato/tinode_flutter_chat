import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What the in-app camera took: a photo or a video, at [path].
final class CameraCapture with ValueObject {
  const CameraCapture(this.path, {required this.isVideo});

  final String path;
  final bool isVideo;

  @override
  List<Object?> get props => [path, isVideo];
}
