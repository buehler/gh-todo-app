import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Formats a `YYYY-MM-DD` (or ISO-8601) date as a short, human-readable day.
///
/// Adds the year only when it differs from the current year, so a due date in
/// the current year reads as "Apr 20" while a date in a past or future year
/// reads as "Apr 20, 2025".
String formatDueDate(String iso) {
  final date = DateTime.parse(iso);
  final now = DateTime.now();
  final pattern = date.year == now.year ? 'MMM d' : 'MMM d, y';
  return DateFormat(pattern).format(date);
}

/// Formats an ISO-8601 timestamp as a compact relative string, e.g. "2d ago",
/// "3 minutes ago". Uses `timeago`'s English-short locale for brevity.
String formatRelative(String iso) {
  final dt = DateTime.parse(iso);
  return timeago.format(dt, locale: 'en_short');
}
