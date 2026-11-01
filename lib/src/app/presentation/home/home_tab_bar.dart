import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/app/domain/home_tab.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_unread_badge.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The floating glass tab bar: one tab per [tabs], a lens sliding under
/// the [current] one on the theme's spring, and the unread count on the
/// chats tab. Picking a tab ticks the haptics. Watches nothing; the badge
/// watches the count.
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    required this.tabs,
    required this.current,
    required this.onSelected,
    super.key,
  });

  static const height = 66.0;
  static const sideInset = 16.0;
  static const _bottomGap = 26.0;
  static const _homeIndicatorGap = 8.0;
  static const _padding = 6.0;
  static const _radius = 33.0;

  static final ImageFilter _filter = glassFilter(24);

  /// How far the bar sits from the bottom of the screen. Over an iOS home
  /// indicator it sits 8 px from the edge, the indicator across it, as
  /// the system's own floating tab bars do: the indicator is a gesture
  /// strip, not a button. Elsewhere 26 px, or the system's bottom inset
  /// when that is more, so it clears the navigation buttons.
  static double bottomOf(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    if (inset > 0 && defaultTargetPlatform == TargetPlatform.iOS) {
      return _homeIndicatorGap;
    }
    return math.max(_bottomGap, inset);
  }

  /// The space the bar covers at the bottom of the screen.
  static double footprintOf(BuildContext context) => bottomOf(context) + height;

  final List<HomeTab> tabs;
  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final index = tabs.indexOf(current);
    final last = tabs.length - 1;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 34,
              spreadRadius: -12,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: _filter,
            child: Container(
              height: height,
              padding: const EdgeInsets.all(_padding),
              decoration: BoxDecoration(
                color: theme.glassColor,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: theme.glassEdgeColor),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment: AlignmentDirectional(
                        last == 0 ? 0 : -1 + 2 * index / last,
                        0,
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : theme.springDuration,
                      curve: theme.springCurve,
                      child: FractionallySizedBox(
                        widthFactor: 1 / tabs.length,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.tabBarLensColor,
                            borderRadius: BorderRadius.circular(
                              _radius - _padding,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      role: SemanticsRole.tabBar,
                      container: true,
                      explicitChildNodes: true,
                      child: Row(
                        children: [
                          for (final tab in tabs)
                            Expanded(
                              child: _Tab(
                                tab: tab,
                                selected: tab == current,
                                onTap: () => _select(tab),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(HomeTab tab) {
    if (tab != current) {
      unawaited(HapticFeedback.selectionClick());
      onSelected(tab);
    }
  }
}

/// One tab: its icon (with the unread count on chats) over its label, in
/// the link colour while [selected].
class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.selected, required this.onTap});

  final HomeTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final (label, icon, selectedIcon) = switch (tab) {
      HomeTab.chats => (
        strings.chatListTitle,
        icons.chatsTab,
        icons.chatsTabSelected,
      ),
      HomeTab.calls => (
        strings.callsTitle,
        icons.callsTab,
        icons.callsTabSelected,
      ),
      HomeTab.settings => (
        strings.settingsTitle,
        icons.settingsTab,
        icons.settingsTabSelected,
      ),
    };
    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(27),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: selected ? chat.linkColor : theme.colorScheme.outline,
            ),
            duration: chat.fadeDuration,
            builder: (context, color, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      size: 24,
                      color: color,
                    ),
                    if (tab == HomeTab.chats)
                      const PositionedDirectional(
                        top: -3,
                        start: 18,
                        child: HomeUnreadBadge(),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
