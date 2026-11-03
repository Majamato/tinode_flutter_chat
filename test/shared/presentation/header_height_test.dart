import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_header.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

/// A [Scaffold] caps its app bar at the status bar plus the preferred
/// height, so a preferred height that is too small would squash the
/// header there without failing anything. Laid out on its own, free to
/// take the height it needs, the header must need exactly that.
void main() {
  const statusBar = 24.0;

  Future<double> naturalHeight(
    WidgetTester tester,
    PreferredSizeWidget header, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TinodeChatTheme.materialTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: statusBar),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Align(alignment: Alignment.topCenter, child: header),
          ),
        ),
      ),
    );
    return tester.getSize(find.byWidget(header)).height;
  }

  for (final textScale in [1.0, 2.0]) {
    testWidgets('a titled app bar is as tall as it says, text at '
        '$textScale', (tester) async {
      const header = TinodeAppBar(title: Text('Settings'));
      expect(
        await naturalHeight(tester, header, textScale: textScale),
        statusBar + header.preferredSize.height,
      );
    });

    testWidgets('an app bar with buttons and a bottom is as tall as it '
        'says, text at $textScale', (tester) async {
      const header = TinodeAppBar(
        leading: SizedBox.square(dimension: 44),
        title: Text('A title long enough to need ellipsis on a phone'),
        actions: [SizedBox.square(dimension: 44)],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: SizedBox(height: 40),
        ),
      );
      expect(
        await naturalHeight(tester, header, textScale: textScale),
        statusBar + header.preferredSize.height,
      );
    });

    testWidgets('the chat list header is as tall as it says, text at '
        '$textScale', (tester) async {
      const header = ChatListHeader(accountMenu: false);
      expect(
        await naturalHeight(tester, header, textScale: textScale),
        statusBar + header.preferredSize.height,
      );
    });
  }
}
