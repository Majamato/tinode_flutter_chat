import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/file_download_controller.dart';
import 'package:tinode_flutter_chat/src/attachments/application/sent_stand_ins.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/file_download_state.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/stand_in_picture.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_duration_chip.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_play_glyph.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_player_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A video in a message, in the space its size asks for: its poster (grey
/// without one), a play button and how long it plays. One the user just
/// sent shows its outgoing bubble's picture (its stand-in) until the poster
/// is drawn, so it never blinks. A tap downloads it, with progress on the
/// button, and plays it full screen. Watches its download.
class VideoBubbleContent extends ConsumerWidget {
  const VideoBubbleContent({required this.video, this.clientId, super.key});

  final VideoAttachment video;

  /// The client ID of the user's own message, whose outgoing bubble may
  /// have left a stand-in.
  final String? clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const width = ImageBubbleContent.width;
    final strings = TinodeChatStrings.of(context);
    final fileRef = video.ref;
    final download = fileRef == null
        ? const DownloadIdle()
        : ref.watch(fileDownloadControllerProvider(fileRef));
    final poster = video.poster;
    final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();
    final standIn = switch (clientId) {
      final clientId? => ref.watch(sentStandInsProvider)[clientId],
      null => null,
    };

    return Semantics(
      button: true,
      label: video.name ?? strings.videoLabel,
      onTapHint: strings.playVideo,
      child: GestureDetector(
        onTap: fileRef == null ? null : () => _play(context, ref, fileRef),
        child: SizedBox(
          width: width,
          height: width / video.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              TinodeChatTheme.of(context).photoRadius,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Until its first frame the poster paints nothing, so what
                // is under it shows.
                StandInPicture(standIn: standIn, cacheWidth: cacheWidth),
                if (poster != null)
                  Image(
                    image: ResizeImage.resizeIfNeeded(
                      cacheWidth,
                      null,
                      MemoryImage(poster),
                    ),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                Center(
                  child: VideoPlayGlyph(
                    busy: switch (download) {
                      Downloading(:final fraction) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          value: fraction,
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                      DownloadFailed() => Icon(
                        TinodeChatIcons.of(context).retry,
                        color: Colors.white,
                        size: ChatIconSize.large,
                      ),
                      _ => null,
                    },
                  ),
                ),
                PositionedDirectional(
                  start: 6,
                  top: 6,
                  child: VideoDurationChip(duration: video.duration),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    String fileRef,
  ) async {
    final file = await ref
        .read(fileDownloadControllerProvider(fileRef).notifier)
        .fetch();
    if (file == null || !context.mounted) {
      return;
    }
    final strings = TinodeChatStrings.of(context);
    if (file.path case final path?) {
      unawaited(
        VideoPlayerScreen.open(context, video.name ?? strings.videoLabel, path),
      );
    } else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(strings.videoFailed)));
    }
  }
}
