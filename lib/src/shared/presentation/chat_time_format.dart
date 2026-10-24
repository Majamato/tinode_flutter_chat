import 'package:flutter/material.dart';

/// Formats message times with the app's [MaterialLocalizations].
extension ChatTimeFormat on MaterialLocalizations {
  /// The time of day, e.g. `14:05` or `2:05 PM`.
  String messageTime(DateTime time) =>
      formatTimeOfDay(TimeOfDay.fromDateTime(time.toLocal()));

  /// The time for today's messages, [yesterday] for yesterday's when
  /// given, else the date, e.g. `Mar 3`.
  String chatListTime(DateTime time, {String? yesterday, DateTime? now}) {
    final local = time.toLocal();
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return switch (calendarDaysBetween(local, today)) {
      0 => messageTime(local),
      1 when yesterday != null => yesterday,
      _ => formatShortMonthDay(local),
    };
  }
}

/// How many calendar days [to] is after [from], ignoring the time of day.
/// Counted on UTC dates, so a day that a clock change makes 23 or 25 hours
/// long still counts as one.
int calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The length of a call, e.g. `0:42`, `12:05` or `1:02:09`.
String formatCallDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60);
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return duration.inHours > 0
      ? '${duration.inHours}:${twoDigits(minutes)}:$seconds'
      : '$minutes:$seconds';
}
