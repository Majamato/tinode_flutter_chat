import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_icon_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The way back from a screen: a chevron in the link colour on a glass
/// pill, for `TinodeAppBar.leading`. It pops the route it is on.
///
/// [label] names the screen it goes back to, on one line, in the link
/// colour; without it the button is only the chevron, the default. Every
/// screen of the chat that can go back uses one; a host
/// that replaces a bar in `TinodeChat.appBarBuilder` can too:
///
/// ```dart
/// appBarBuilder: (context, screen, defaultAppBar) => switch (screen) {
///   TinodeAccountScreen() => const TinodeAppBar(
///     leading: TinodeBackButton(label: Text('Me')),
///     title: Text('Account'),
///   ),
///   _ => defaultAppBar,
/// },
/// ```
class TinodeBackButton extends StatelessWidget {
  /// Creates a back button; all parts are optional.
  const TinodeBackButton({this.label, this.badge, this.tooltip, super.key});

  /// How much of the screen's width it takes at most, so a long name leaves
  /// room for the title.
  static const _maxWidth = 0.45;

  /// The name of the screen it goes back to, usually a [Text]; cut with an
  /// ellipsis when too long.
  final Widget? label;

  /// After the chevron, e.g. how many messages wait unread.
  final Widget? badge;

  /// What it says on a long press and to a screen reader; the platform's
  /// word for "Back" by default.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final TinodeBackButton(:label, :badge) = this;
    final color = TinodeChatTheme.of(context).linkColor;
    final message =
        tooltip ?? MaterialLocalizations.of(context).backButtonTooltip;
    return Tooltip(
      message: message,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: message,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * _maxWidth,
          ),
          child: GlassSurface(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => Navigator.of(context).maybePop(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: GlassIconButton.size,
                    minHeight: GlassIconButton.size,
                    maxHeight: GlassIconButton.size,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: label == null ? 8 : 6,
                      end: label != null
                          ? 14
                          : badge != null
                          ? 8
                          : 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: label == null ? 4 : 2,
                      children: [
                        Icon(
                          TinodeChatIcons.of(context).back,
                          size: 24,
                          color: color,
                        ),
                        ?badge,
                        if (label != null)
                          Flexible(
                            child: DefaultTextStyle.merge(
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: label,
                            ),
                          ),
                      ],
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
