import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_player_view.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_trim_bar.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// What the preview hands back on Send: the staged file and its caption.
typedef PreviewedAttachment = ({OutgoingAttachment attachment, String caption});

/// What the preview needs done, so that it can watch nothing itself.
final class AttachmentPreviewActions {
  const AttachmentPreviewActions({
    required this.stage,
    required this.discard,
    required this.trim,
    required this.maxClip,
    required this.frames,
  });

  /// Stages the file; null when it is refused.
  final Future<OutgoingAttachment?> Function(PickedFile file) stage;

  /// Forgets what [stage] returned, when it won't be sent.
  final Future<void> Function(OutgoingAttachment attachment) discard;

  /// What [stage] returned, to send only a part of it.
  final Future<OutgoingAttachment> Function(
    OutgoingAttachment attachment,
    VideoTrim range,
  )
  trim;

  /// The longest part of a video that can be sent.
  final Duration Function(PickedFile file, Duration duration) maxClip;

  /// Stills to choose a video's part by; null where it can't be chosen.
  final Stream<Uint8List?> Function(
    PickedFile file, {
    required int count,
    required Duration duration,
  })?
  frames;
}

/// The file to send, from the moment it is being picked: a spinner until
/// the file arrives, then the image (fading in once decoded), the video to
/// play, on black, with a bar to choose the part to send, or the file's
/// name and size, with a caption field. The file is
/// staged meanwhile, so that Send has little left to do; Send pressed too
/// early waits here, spinning. Goes away by itself when nothing was picked
/// or the file is refused. Watches nothing itself.
class AttachmentPreviewScreen extends StatefulWidget {
  const AttachmentPreviewScreen({
    required this.picked,
    required this.actions,
    super.key,
  });

  /// Shows the preview of what [picked] brings; what to send, or null when
  /// cancelled or refused.
  static Future<PreviewedAttachment?> open(
    BuildContext context, {
    required Future<PickedFile?> picked,
    required AttachmentPreviewActions actions,
  }) => Navigator.of(context).push(
    MaterialPageRoute<PreviewedAttachment>(
      builder: (_) => AttachmentPreviewScreen(picked: picked, actions: actions),
    ),
  );

  /// The file being picked; null when nothing was.
  final Future<PickedFile?> picked;

  final AttachmentPreviewActions actions;

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  static const _fadeIn = Duration(milliseconds: 150);

  final _caption = TextEditingController();

  /// Null until picked.
  PickedFile? _file;

  /// Null until picked.
  Future<OutgoingAttachment?>? _staged;

  /// Send was pressed, and waits for the file to be staged.
  var _sending = false;

  /// Whether the staged file went to the caller, who now owns it.
  var _handedOver = false;

  /// The part of the video to send; null until its player is ready, or
  /// when it can't be chosen.
  final _clip = ValueNotifier<VideoTrim?>(null);

  /// The video's bar, once its player knows how long it plays.
  Widget? _clipBar;

  /// How long the video plays, once known.
  Duration? _total;

  /// Done once the video's player has loaded or failed.
  final _playerReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final file = await widget.picked;
    if (!mounted) {
      return;
    }
    if (file == null) {
      _close();
      return;
    }
    final staged = widget.actions.stage(file);
    setState(() {
      _file = file;
      _staged = staged;
    });
    if (await staged == null && mounted) {
      _close();
    }
  }

  /// Leaves at once, without the animation of going back: there was
  /// nothing to see here.
  void _close() {
    Navigator.of(context).removeRoute(ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _caption.dispose();
    _clip.dispose();
    if (!_handedOver) {
      unawaited(
        _staged?.then((attachment) async {
          if (attachment != null) {
            await widget.actions.discard(attachment);
          }
        }),
      );
    }
    super.dispose();
  }

  /// Sets up the part to choose, now that the video's length is known.
  void _onPlayerReady(Duration? total) {
    if (!_playerReady.isCompleted) {
      _playerReady.complete();
    }
    final file = _file;
    final frames = widget.actions.frames;
    if (total == null || total <= Duration.zero || file == null) {
      return;
    }
    _total = total;
    if (frames == null) {
      return;
    }
    final maxLength = widget.actions.maxClip(file, total);
    _clip.value = VideoTrim.initial(total, maxLength);
    setState(() {
      _clipBar = VideoTrimBar(
        clip: _clip,
        total: total,
        maxLength: maxLength,
        frames: frames(file, count: VideoTrimBar.frameCount, duration: total),
      );
    });
  }

  Future<void> _send() async {
    final staged = _staged;
    if (staged == null || _sending) {
      return;
    }
    setState(() => _sending = true);
    var attachment = await staged;
    if (_file case PickedFile(isVideo: true, path: _?)) {
      await _playerReady.future;
    }
    if (attachment == null || !mounted) {
      return;
    }
    final clip = _clip.value;
    final total = _total;
    if (clip != null && total != null && !clip.coversAll(total)) {
      attachment = await widget.actions.trim(attachment, clip);
      if (!mounted) {
        return;
      }
    }
    _handedOver = true;
    final previewed = (attachment: attachment, caption: _caption.text);
    Navigator.of(context).pop<PreviewedAttachment>(previewed);
  }

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final file = _file;
    final path = file?.path;
    return GlassScaffold(
      screen: const TinodeAttachmentPreviewScreen(),
      appBar: TinodeAppBar(
        title: Text(file?.name ?? ''),
        opaque: true,
        leading: const TinodeBackButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: file == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(strings.preparingAttachment),
                        ],
                      )
                    : file.isVideo && path != null
                    // The player is white, for the black of full screen:
                    // in a light theme it would not show.
                    ? SizedBox.expand(
                        child: ColoredBox(
                          color: Colors.black,
                          child: VideoPlayerView(
                            path: path,
                            clip: _clip,
                            clipBar: _clipBar,
                            onReady: _onPlayerReady,
                          ),
                        ),
                      )
                    : file.isImage && path != null
                    ? Image.file(
                        File(path),
                        cacheWidth:
                            (MediaQuery.sizeOf(context).width *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        // A large photo takes a moment to decode: it fades
                        // in rather than pops.
                        frameBuilder: (context, child, frame, synchronous) =>
                            synchronous
                            ? child
                            : AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: _fadeIn,
                                curve: Curves.easeOut,
                                child: child,
                              ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icons.file, size: ChatIconSize.hero),
                          const SizedBox(height: 8),
                          Text(file.name, textAlign: TextAlign.center),
                          Text(fileSizeLabel(file.length)),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      // No keyboard until asked for: rising, it would
                      // shrink the picture as it appears.
                      controller: _caption,
                      decoration: InputDecoration(
                        hintText: strings.captionHint,
                      ),
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => unawaited(_send()),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(icons.send),
                    onPressed: file == null || _sending
                        ? null
                        : () => unawaited(_send()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
