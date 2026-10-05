import 'package:intl/intl.dart';

/// Dates as the home screen widgets save and show them.
abstract final class WidgetDates {
  /// yyyy-MM-dd, the format the native widgets compare with their "today".
  static String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// "14 ott". Falls back to "14/10" if the locale's date symbols are not
  /// loaded (the widget may be written before the first screen is built).
  static String short(DateTime d, String locale) {
    try {
      return DateFormat.MMMd(locale).format(d);
    } catch (_) {
      return '${d.day}/${d.month}';
    }
  }
}
