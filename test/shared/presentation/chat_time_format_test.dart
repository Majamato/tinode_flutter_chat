import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';

void main() {
  const localizations = DefaultMaterialLocalizations();

  test('the chat list says the time today, yesterday, else the date', () {
    final now = DateTime(2026, 10, 23, 9);
    String label(DateTime time) =>
        localizations.chatListTime(time, yesterday: 'Yesterday', now: now);

    expect(label(DateTime(2026, 10, 23, 8, 5)), '8:05 AM');
    expect(label(DateTime(2026, 10, 22, 23, 55)), 'Yesterday');
    expect(label(DateTime(2026, 10, 20)), 'Oct 20');
    // Without the word, yesterday is a date too.
    expect(
      localizations.chatListTime(DateTime(2026, 10, 22), now: now),
      'Oct 22',
    );
  });

  test('times are on the 12-hour clock, whatever the locale', () {
    String time(int hour, int minute) =>
        localizations.messageTime(DateTime(2026, 10, 23, hour, minute));

    expect(time(14, 5), '2:05 PM');
    expect(time(0, 30), '12:30 AM');
    expect(time(12, 0), '12:00 PM');
    expect(time(23, 59), '11:59 PM');
  });

  test('calendar days ignore the time of day and clock changes', () {
    expect(
      calendarDaysBetween(DateTime(2026, 10, 24, 23), DateTime(2026, 10, 25)),
      1,
    );
    // Local midnights 23 hours apart, as on a spring-forward day, are a day.
    expect(
      calendarDaysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 29, 0, 30)),
      1,
    );
    expect(calendarDaysBetween(DateTime(2026, 1, 2), DateTime(2026, 1, 2)), 0);
  });
}
