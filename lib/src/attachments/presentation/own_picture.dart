import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/sent_stand_ins.dart';

/// A photo's or video's own picture in its bubble, over its
/// `StandInPicture`. Once its first frame is on screen, the stand-in message
/// [clientId] left is no longer needed and goes. Removing it notifies
/// nothing, so this rebuilds nothing. Watches nothing.
class OwnPicture extends ConsumerStatefulWidget {
  const OwnPicture({
    required this.image,
    required this.cacheWidth,
    this.clientId,
    super.key,
  });

  final ImageProvider<Object> image;

  /// The width, in physical pixels, the picture is decoded at.
  final int cacheWidth;

  /// The client ID of the user's own message, whose outgoing bubble may
  /// have left a stand-in.
  final String? clientId;

  @override
  ConsumerState<OwnPicture> createState() => _OwnPictureState();
}

class _OwnPictureState extends ConsumerState<OwnPicture> {
  /// Whether removing the stand-in is done or on its way. An animated
  /// picture has many frames; only the first counts.
  var _removed = false;

  Widget _onFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame != null && !_removed) {
      _removed = true;
      WidgetsBinding.instance.addPostFrameCallback(_removeStandIn);
    }
    return child;
  }

  void _removeStandIn(Duration _) {
    if (mounted) {
      ref.read(sentStandInsProvider).remove(widget.clientId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: ResizeImage.resizeIfNeeded(widget.cacheWidth, null, widget.image),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: widget.clientId == null ? null : _onFrame,
    );
  }
}
