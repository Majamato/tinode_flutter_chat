import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/app_bar_builder_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/edge_fade.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_below.dart';

/// A screen whose [body] runs under its floating bars: the [appBar] (or
/// what the host's `TinodeChat.appBarBuilder` makes of it for [screen]) and
/// the [bottomBar], if any.
///
/// The [Scaffold] lays the body out behind both and hands it their heights
/// as `MediaQuery` padding in the same layout pass: lists pad by
/// `MediaQuery.paddingOf`, and never measure a bar, so a host's bar of any
/// height works. With a [bottomBar] the body doesn't shrink for the
/// keyboard; the bar rises above it instead, and its height (keyboard
/// included) reaches the body. Without one, the system's own bars over the
/// body's bottom get a fade of the background behind them, solid under
/// their lower half and clear at their top, and take no touch through it.
/// Under [GlassBelow] (the tab bar) the fade is only a light veil: the
/// content scrolls under the glass, which blurs it, and takes no touch
/// there either.
///
/// All the glass on the screen shares one [BackdropGroup], so the blur
/// reads what is behind the bars once. Watches only the host's builder.
class GlassScaffold extends StatefulWidget {
  const GlassScaffold({
    required this.screen,
    required this.appBar,
    required this.body,
    this.bottomBar,
    this.backgroundColor,
    this.floatingActionButton,
    super.key,
  });

  final TinodeScreen screen;
  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? bottomBar;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  @override
  State<GlassScaffold> createState() => _GlassScaffoldState();
}

class _GlassScaffoldState extends State<GlassScaffold> {
  /// Kept, so a rebuild doesn't regroup every piece of glass.
  final _backdrop = BackdropKey();

  @override
  Widget build(BuildContext context) {
    final builder = AppBarBuilderScope.maybeOf(context);
    final GlassScaffold(:screen, :appBar, :bottomBar) = widget;
    return BackdropGroup(
      backdropKey: _backdrop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        resizeToAvoidBottomInset: bottomBar == null,
        backgroundColor: widget.backgroundColor,
        appBar: builder == null ? appBar : builder(context, screen, appBar),
        body: bottomBar == null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  widget.body,
                  _BottomEdge(
                    color:
                        widget.backgroundColor ??
                        Theme.of(context).scaffoldBackgroundColor,
                  ),
                ],
              )
            : widget.body,
        bottomNavigationBar: bottomBar,
        floatingActionButton: widget.floatingActionButton,
      ),
    );
  }
}

/// The fade at the bottom of a body that something floats over: as tall as
/// the body's bottom padding, clear at its top so the content above that
/// room stays crisp. Under the system's bars it is solid under the room's
/// lower half; under [GlassBelow] (the tab bar) it is only a veil, [_veil]
/// of the background at the screen's edge, so the rows still show around
/// the glass. Either way touches on that room stop there, so a row half
/// under the bar can't be opened by a near miss.
class _BottomEdge extends StatelessWidget {
  const _BottomEdge({required this.color});

  /// How much of the background the veil under floating glass lays over
  /// the content at the screen's edge.
  static const _veil = 0.6;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    if (bottom == 0) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: bottom,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (GlassBelow.of(context))
              EdgeFade(
                color: color.withValues(alpha: color.a * _veil),
                edge: VerticalDirection.down,
              )
            else
              EdgeFade(color: color, edge: VerticalDirection.down, solid: 0.5),
            const AbsorbPointer(),
          ],
        ),
      ),
    );
  }
}
