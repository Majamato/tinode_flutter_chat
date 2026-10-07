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

/// The length of a call, e.g. `0:42`, `12:05` or `1:02:09`.
String formatCallDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60);
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return duration.inHours > 0
      ? '${duration.inHours}:${twoDigits(minutes)}:$seconds'
      : '$minutes:$seconds';
}
