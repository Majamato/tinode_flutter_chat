import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_bubble_content.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';

void main() {
  const foreground = Color(0xFF000001);

  Future<void> pump(
    WidgetTester tester,
    CallRecord call, {
    bool outgoing = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CallBubbleContent(
          call: call,
          outgoing: outgoing,
          color: foreground,
        ),
      ),
    ),
  );

  Color colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  testWidgets('a finished call shows its length', (tester) async {
    await pump(
      tester,
      const CallRecord(
        state: CallState.finished,
        audioOnly: true,
        duration: Duration(minutes: 2, seconds: 5),
      ),
      outgoing: true,
    );

    expect(find.text('Outgoing voice call'), findsOneWidget);
    expect(colorOf(tester, '2:05'), foreground);
    expect(find.byIcon(Icons.call_made), findsOneWidget);
  });

  testWidgets('a missed call stands out', (tester) async {
    await pump(tester, const CallRecord(state: CallState.missed));

    expect(find.text('Incoming video call'), findsOneWidget);
    final error = ThemeData().colorScheme.error;
    expect(colorOf(tester, 'Missed'), error);
    expect(find.byIcon(Icons.call_missed), findsOneWidget);
  });

  testWidgets('the caller sees an unanswered call as no answer', (
    tester,
  ) async {
    await pump(
      tester,
      const CallRecord(state: CallState.missed),
      outgoing: true,
    );

    expect(find.text('No answer'), findsOneWidget);
    expect(find.byIcon(Icons.call_missed_outgoing), findsOneWidget);
  });

  testWidgets('a running call is in progress', (tester) async {
    await pump(tester, const CallRecord(state: CallState.accepted));

    expect(find.text('In progress'), findsOneWidget);
  });

  test('call lengths read like a clock', () {
    expect(formatCallDuration(const Duration(seconds: 42)), '0:42');
    expect(
      formatCallDuration(const Duration(minutes: 12, seconds: 5)),
      '12:05',
    );
    expect(
      formatCallDuration(const Duration(hours: 1, minutes: 2, seconds: 9)),
      '1:02:09',
    );
  });
}
