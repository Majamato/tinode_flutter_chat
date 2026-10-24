import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_video_view.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The user's own camera in a video call, as a 108 × 152 tile with a
/// light edge and a deep shadow. While the camera is off it shows the
/// user's avatar and "Camera off".
///
/// While the cameras swap, its video blurs, and the tile turns edge-on and
/// back once the media says which camera is in use (with Reduce motion it
/// only blurs). The video stays blurred until the new camera's frames
/// arrive, or for at most [newCameraWait]: until then the renderer may
/// still show the old camera's last frame. Watches the local stream and
/// the camera state.
class CallLocalPreview extends ConsumerStatefulWidget {
  const CallLocalPreview({super.key});

  static const size = Size(108, 152);

  /// The longest the video stays blurred after a swap when the renderer
  /// reports no new frames, e.g. two cameras of the same rotation and size.
  static const newCameraWait = Duration(milliseconds: 1500);

  static const _radius = BorderRadius.all(Radius.circular(22));
  static const _turn = Duration(milliseconds: 200);
  static const _blur = 18.0;

  @override
  ConsumerState<CallLocalPreview> createState() => _CallLocalPreviewState();
}

class _CallLocalPreviewState extends ConsumerState<CallLocalPreview>
    with SingleTickerProviderStateMixin {
  /// 0 facing the user, 1 edge-on.
  late final _flip = AnimationController(
    vsync: this,
    duration: CallLocalPreview._turn,
  )..addStatusListener(_turnBackOnceEdgeOn);
  CurvedAnimation? _angle;

  /// From the request until the media answers.
  var _switching = false;

  /// From the request until the new camera's frames show.
  var _blurred = false;
  var _newFrames = false;
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _angle?.dispose();
    _angle = CurvedAnimation(
      parent: _flip,
      curve: Curves.easeIn,
      reverseCurve: TinodeChatTheme.of(context).springCurve.flipped,
    );
  }

  @override
  void dispose() {
    _wait?.cancel();
    _angle?.dispose();
    _flip.dispose();
    super.dispose();
  }

  /// Turns the tile away while the cameras swap, and back once the media
  /// answered and it is edge-on, whichever comes last. The blur stays
  /// until the new camera's frames arrive.
  void _follow(bool switching) {
    _switching = switching;
    if (switching) {
      _wait?.cancel();
      _newFrames = false;
      setState(() => _blurred = true);
    } else if (_newFrames) {
      _unblur();
    } else {
      _wait = Timer(CallLocalPreview.newCameraWait, _unblur);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _flip.value = 0;
    } else if (switching) {
      unawaited(_flip.forward());
    } else if (_flip.isCompleted) {
      unawaited(_flip.reverse());
    }
  }

  /// Frames of another rotation or size: the new camera, once a swap runs.
  void _onFramesChanged() {
    if (!_blurred) {
      return;
    }
    _newFrames = true;
    if (!_switching) {
      _unblur();
    }
  }

  void _unblur() {
    _wait?.cancel();
    _wait = null;
    if (mounted && _blurred) {
      setState(() => _blurred = false);
    }
  }

  void _turnBackOnceEdgeOn(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_switching) {
      unawaited(_flip.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      callControllerProvider.select((c) => c?.switchingCamera ?? false),
      (_, switching) => _follow(switching),
    );
    final (:stream, :on, :front) = ref.watch(
      callControllerProvider.select(
        (c) => (
          stream: c?.localStream,
          on: c?.cameraOn ?? false,
          front: c?.frontCamera ?? true,
        ),
      ),
    );
    final theme = TinodeChatTheme.of(context);
    final strings = TinodeChatStrings.of(context);
    final angle = _angle!;
    const size = CallLocalPreview.size;
    const radius = CallLocalPreview._radius;
    final tile = Semantics(
      label: strings.yourCamera,
      image: true,
      child: Container(
        width: size.width,
        height: size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.callBackgroundColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: theme.callShadeColor,
              offset: const Offset(0, 16),
              blurRadius: 36,
              spreadRadius: -12,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: theme.callOutlineColor, width: 1.5),
        ),
        child: switch ((stream, on)) {
          // Blurred while the cameras swap: the old camera's last frame
          // may show, mirrored for the new one, until new frames come.
          (final stream?, true) => TweenAnimationBuilder<double>(
            tween: Tween(end: _blurred ? CallLocalPreview._blur : 0),
            duration: _blurred ? Duration.zero : theme.fadeDuration,
            builder: (context, sigma, child) => ImageFiltered(
              enabled: sigma > 0,
              imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            ),
            child: CallVideoView(
              stream: stream,
              mirror: front,
              onFramesChanged: _onFramesChanged,
            ),
          ),
          (_, true) => const SizedBox.shrink(),
          (_, false) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _OwnAvatar(),
              const SizedBox(height: 8),
              Text(
                strings.cameraOff,
                style: TextStyle(
                  color: theme.onCallColor.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        },
      ),
    );
    return AnimatedBuilder(
      animation: angle,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(angle.value * math.pi / 2),
        child: child,
      ),
      child: tile,
    );
  }
}

/// The user's own avatar, 48 px, white initials on the palette's primary.
/// Watches the user's photo and initials.
class _OwnAvatar extends ConsumerWidget {
  const _OwnAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (photo, initials) = ref.watch(
      profileControllerProvider.select(
        (s) => (s.value?.photo, s.value?.initials ?? ''),
      ),
    );
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primaryContainer: chat.callBlobColors.first.withValues(alpha: 1),
          onPrimaryContainer: chat.onCallColor,
        ),
      ),
      child: ProfileAvatar(initials: initials, photo: photo, radius: 24),
    );
  }
}
