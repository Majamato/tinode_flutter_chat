import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/reconnecting_title.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

class _Link extends ReconnectingNotice {
  @override
  bool build() => false;

  // A setter would be a public notifier property (riverpod_lint).
  // ignore: use_setters_to_change_properties
  void lower({required bool down}) => state = down;
}

void main() {
  const strings = TinodeChatStrings();
  late ProviderContainer container;

  Future<void> pumpTitle(WidgetTester tester, {bool still = false}) async {
    container = ProviderContainer(
      overrides: [reconnectingNoticeProvider.overrideWith(_Link.new)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: TinodeChatTheme.materialTheme(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: still),
            child: const Scaffold(
              appBar: TinodeAppBar(
                title: ReconnectingTitle(title: Text('Chats')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void setDown({required bool down}) =>
      (container.read(reconnectingNoticeProvider.notifier) as _Link).lower(
        down: down,
      );

  /// The spring's lift and growth on the incoming title, if any.
  Iterable<Transform> springs(WidgetTester tester) => tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(ReconnectingTitle),
          matching: find.byType(Transform),
        ),
      )
      .where((t) => !t.transform.isIdentity());

  testWidgets('shows the title while connected', (tester) async {
    await pumpTitle(tester);

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text(strings.reconnecting), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a lost link swaps in a spinner and the muted text, on a '
      'spring', (tester) async {
    await pumpTitle(tester);

    setDown(down: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(springs(tester), isNotEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Chats'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final text = tester.widget<Text>(find.text(strings.reconnecting));
    final scheme = TinodeChatTheme.materialTheme().colorScheme;
    expect(text.style?.color, scheme.onSurfaceVariant);
    expect(
      tester
          .getSemantics(find.text(strings.reconnecting))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );

    setDown(down: false);
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text(strings.reconnecting), findsNothing);
  });

  testWidgets('with Reduce motion it only fades', (tester) async {
    await pumpTitle(tester, still: true);

    setDown(down: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(springs(tester), isEmpty);
    expect(
      find.ancestor(
        of: find.text(strings.reconnecting),
        matching: find.byType(FadeTransition),
      ),
      findsWidgets,
    );
  });
}
