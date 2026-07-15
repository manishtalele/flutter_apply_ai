import 'package:intl/intl.dart';

/// Centralized date/time formatting so the app renders dates consistently.
abstract final class DateFormatter {
  const DateFormatter._();

  static final DateFormat _date = DateFormat('MMM d, y');
  static final DateFormat _dateTime = DateFormat('MMM d, y • h:mm a');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd HH:mm');

  /// e.g. "Jul 15, 2026".
  static String date(DateTime value) => _date.format(value);

  /// e.g. "Jul 15, 2026 • 3:04 PM".
  static String dateTime(DateTime value) => _dateTime.format(value);

  /// Machine-friendly timestamp for CSV export.
  static String iso(DateTime value) => _iso.format(value);

  /// Compact relative label ("Today", "Yesterday", or the date).
  static String relative(DateTime value) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(value.year, value.month, value.day);
    final int diffDays = today.difference(day).inDays;
    if (diffDays == 0) {
      return 'Today';
    }
    if (diffDays == 1) {
      return 'Yesterday';
    }
    return _date.format(value);
  }
}
