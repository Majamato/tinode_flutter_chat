import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The date above the first message of a day: "Today", "Yesterday" or
/// the date, on a pill centred over the wallpaper.
class DateChip extends StatelessWidget {
  const DateChip({required this.time, super.key});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: TinodeChatTheme.of(context).dateChipColor,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Text(
              dayLabel(
                TinodeChatStrings.of(context),
                MaterialLocalizations.of(context),
                time,
              ),
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Today", "Yesterday", or the date of [time] in the app's language,
/// with the year when it isn't this year's.
String dayLabel(
  TinodeChatStrings strings,
  MaterialLocalizations localizations,
  DateTime time, {
  DateTime? now,
}) {
  final day = DateUtils.dateOnly(time.toLocal());
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  return switch (today.difference(day).inDays) {
    0 => strings.today,
    1 => strings.yesterday,
    _ when day.year == today.year => localizations.formatMediumDate(day),
    _ => localizations.formatFullDate(day),
  };
}
