import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/app/domain/home_tab.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/calls_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/settings_screen.dart';

/// The chat navigator's first route with the tab bar: the chats, the
/// calls history and the settings, over the floating [HomeTabBar].
///
/// A tab is built the first time it shows and then kept, its tickers and
/// focus off while hidden. The tabs see the bar's footprint as the bottom
/// padding, so lists and floating buttons clear it. System back on another
/// tab goes to the chats first. [tab] is the current tab; the navigator
/// owns it, to show the chats when it opens one. Watches nothing.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({required this.tab, super.key});

  final ValueNotifier<HomeTab> tab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final List<HomeTab> _tabs = HomeTab.offeredBy(
    ref.read(tinodeChatFeaturesProvider),
  );

  /// The tabs shown so far, which stay built.
  final _built = <HomeTab>{};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.tab,
      builder: (context, picked, _) {
        final current = _tabs.contains(picked) ? picked : HomeTab.chats;
        _built.add(current);
        final media = MediaQuery.of(context);
        final footprint = HomeTabBar.footprintOf(context);
        return PopScope(
          canPop: current == HomeTab.chats,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              widget.tab.value = HomeTab.chats;
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(bottom: footprint),
                    viewPadding: media.viewPadding.copyWith(bottom: footprint),
                  ),
                  child: IndexedStack(
                    index: _tabs.indexOf(current),
                    sizing: StackFit.expand,
                    children: [
                      for (final tab in _tabs)
                        if (_built.contains(tab))
                          TickerMode(
                            enabled: tab == current,
                            child: ExcludeFocus(
                              excluding: tab != current,
                              child: switch (tab) {
                                HomeTab.chats => const ChatListScreen(
                                  inTabs: true,
                                ),
                                HomeTab.calls => const CallsScreen(),
                                HomeTab.settings => const SettingsScreen(),
                              },
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                start: HomeTabBar.sideInset,
                end: HomeTabBar.sideInset,
                bottom: HomeTabBar.bottomOf(context),
                child: HomeTabBar(
                  tabs: _tabs,
                  current: current,
                  onSelected: (tab) => widget.tab.value = tab,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
