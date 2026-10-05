import 'package:flutter/material.dart';

/// Formats message times with the app's [MaterialLocalizations].
extension ChatTimeFormat on MaterialLocalizations {
  /// The time of day, e.g. `14:05` or `2:05 PM`.
  String messageTime(DateTime time) =>
      formatTimeOfDay(TimeOfDay.fromDateTime(time.toLocal()));

  /// The time for today's messages, else the date, e.g. `Mar 3`.
  String chatListTime(DateTime time, {DateTime? now}) {
    final local = time.toLocal();
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return DateUtils.isSameDay(local, today)
        ? messageTime(local)
        : formatShortMonthDay(local);
  }
}
