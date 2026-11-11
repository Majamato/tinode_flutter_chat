import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';

/// The small pill of a voice message showing its [speed], e.g. "1.5×", in
/// [color] on a tint of it; a tap calls [onPressed] to change it. The pill
/// is [height] tall, but taps land on [targetHeight] and [slop] around it
/// too, as it is small for a finger.
class VoiceSpeedButton extends StatelessWidget {
  const VoiceSpeedButton({
    required this.speed,
    required this.color,
    required this.onPressed,
    super.key,
  });

  static const height = 18.0;
  static const targetHeight = 24.0;

  /// The room before the pill, which also parts it from the clock, and
  /// after it.
  static const slop = EdgeInsetsDirectional.only(start: 6, end: 10);

  final VoiceSpeed speed;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final label = switch (speed) {
      VoiceSpeed.normal => strings.voiceSpeedNormal,
      VoiceSpeed.fast => strings.voiceSpeedFast,
      VoiceSpeed.fastest => strings.voiceSpeedFastest,
    };
    return Semantics(
      button: true,
      label: strings.voiceSpeedLabel,
      value: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          height: targetHeight,
          child: Padding(
            padding: slop,
            child: Center(
              widthFactor: 1,
              child: Material(
                color: color.withValues(alpha: 0.15),
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox(
                    height: height,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
