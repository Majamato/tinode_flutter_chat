import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/edge_fade.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_overlay_style.dart';

/// The chat's app bar: floating glass buttons over a fade of the screen's
/// background, with the content scrolling under it.
///
/// [leading] sits at the start, [actions] at the end, 8 px apart, and
/// [title] between them, centred when [centerTitle] (in `titleLarge`,
/// read out as a header). [bottom], e.g. a search field, goes under that
/// row. Text grows to 1.3 times at most, so the row keeps its height.
///
/// Behind it, a fade of [fadeColor] (the theme's `scaffoldBackgroundColor`
/// by default) keeps what isn't on glass readable: it is solid under the
/// status bar and, unless [titleOnGlass], under the title's row, then
/// eases to clear over the rest of the bar and 16 px past it.
/// The bar takes every touch that lands on it.
///
/// Every screen of the chat with an app bar uses one; a host can build its
/// own from it in `TinodeChat.appBarBuilder`:
///
/// ```dart
/// appBarBuilder: (context, screen, defaultAppBar) => switch (screen) {
///   TinodeSettingsScreen() => const TinodeAppBar(title: Text('Me')),
///   _ => defaultAppBar,
/// },
/// ```
class TinodeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an app bar; all parts are optional.
  const TinodeAppBar({
    this.leading,
    this.title,
    this.centerTitle = true,
    this.actions = const [],
    this.bottom,
    this.fadeColor,
    this.titleOnGlass = false,
    this.overlayBrightness,
    super.key,
  });

  /// The height of the row of buttons; buttons are as tall.
  static const rowHeight = 44.0;

  /// Above and below the row, and above [bottom].
  static const _gap = 6.0;
  static const _side = 8.0;
  static const _spacing = 8.0;

  /// The least the fade eases over, below its solid part.
  static const _fadeLength = 24.0;

  /// How far below the bar the fade still runs, so content eases in from
  /// under the bar's last row instead of showing a hard edge.
  static const _fadeOverhang = 16.0;

  /// At the start, e.g. a `TinodeBackButton`.
  final Widget? leading;

  /// The screen's name, or a widget standing for it.
  final Widget? title;

  /// Whether [title] is centred on the bar rather than after [leading].
  final bool centerTitle;

  /// At the end, e.g. glass buttons.
  final List<Widget> actions;

  /// Under the row of buttons, as tall as its preferred size.
  final PreferredSizeWidget? bottom;

  /// What the fade behind the bar starts from; the screen's background by
  /// default.
  final Color? fadeColor;

  /// Whether [title] sits on glass of its own, readable over anything, so
  /// the fade may turn clear behind its row and let the content show (the
  /// chat's name pill). Plain text needs the solid fade behind it.
  final bool titleOnGlass;

  /// How bright what is behind the status bar looks, for a screen that
  /// doesn't follow the theme (the image viewer is always black). The
  /// theme's brightness by default.
  final Brightness? overlayBrightness;

  /// Below the status bar: the [Scaffold] adds that and caps the bar at
  /// the sum.
  @override
  Size get preferredSize => Size.fromHeight(
    _gap +
        rowHeight +
        _gap +
        (bottom == null ? 0 : bottom!.preferredSize.height + _gap),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusBar = MediaQuery.paddingOf(context).top;
    final solid = titleOnGlass ? statusBar : statusBar + _gap + rowHeight;
    final fade = math.max(
      statusBar + preferredSize.height + _fadeOverhang,
      solid + _fadeLength,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: chatOverlayStyle(overlayBrightness ?? theme.brightness),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Stack(
          // The fade may ease out below the bar; only the bar takes touches.
          clipBehavior: Clip.none,
          children: [
            // Nothing under the bar can be tapped through it.
            const Positioned.fill(child: AbsorbPointer()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: fade,
              child: EdgeFade(
                color: fadeColor ?? theme.scaffoldBackgroundColor,
                edge: VerticalDirection.up,
                solid: solid / fade,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_side, _gap, _side, _gap),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: _gap,
                  children: [
                    SizedBox(
                      height: rowHeight,
                      child: NavigationToolbar(
                        leading: leading,
                        middle: title == null
                            ? null
                            : Semantics(
                                header: true,
                                child: DefaultTextStyle.merge(
                                  style: theme.textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: title!,
                                ),
                              ),
                        trailing: actions.isEmpty
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: _spacing,
                                children: actions,
                              ),
                        centerMiddle: centerTitle,
                        middleSpacing: _spacing,
                      ),
                    ),
                    ?bottom,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
