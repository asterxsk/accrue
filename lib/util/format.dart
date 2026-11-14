/// Small, dependency-free formatters. The app is English-only in this build;
/// keeping them here means a locale layer can replace them in one place.
class Fmt {
  const Fmt._();

  static const List<String> _shortWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "Sun, 14 November" — the line above a screen title.
  static String eyebrowDate(DateTime date) =>
      '${_shortWeekdays[date.weekday - 1]}, ${date.day} '
      '${_months[date.month - 1]}';

  /// "14 Nov"
  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1].substring(0, 3)}';

  /// "14 Nov – 20 Nov"
  static String weekRange(DateTime start, DateTime end) =>
      '${shortDate(start)} – ${shortDate(end)}';

  /// Single letter for the weekday row under a chart. Weeks start Monday
  /// unless the setting says Sunday.
  static String weekdayLetter(DateTime date, {bool monday = true}) {
    const mondayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const sundayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return monday
        ? mondayLetters[(date.weekday - 1) % 7]
        : sundayLetters[date.weekday % 7];
  }

  /// "1h 20m", "45m" — logged time on rows and cards.
  static String duration(int seconds) {
    final total = seconds < 0 ? 0 : seconds ~/ 60;
    final h = total ~/ 60;
    final m = total % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// "45m", "1h 30m", "2h" — a target in minutes.
  static String minutes(int total) {
    if (total < 60) return '${total}m';
    final hours = total ~/ 60;
    final rest = total % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  /// "1:05:09" — the running clock.
  static String clock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    final s = safe % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// "08:00" — a reminder time.
  static String time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  /// "16:30" — a reminder stored as minutes after midnight.
  static String minuteOfDay(int minutes) =>
      time((minutes ~/ 60) % 24, minutes % 60);

  /// "16:30" or "4:30 PM", depending on the profile's clock setting.
  static String clockLabel(int minutes, {bool clock24 = true}) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    if (clock24) return time(hour, minute);
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} '
        '${hour < 12 ? 'AM' : 'PM'}';
  }

  /// "8,000", "2.5" — one decimal at most, trailing ".0" dropped.
  static String count(num value) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(1);
    final parts = fixed.split('.');
    final whole = parts.first;
    final decimal = parts.last;
    final buffer = StringBuffer(negative ? '-' : '');
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    if (decimal != '0') buffer.write('.$decimal');
    return buffer.toString();
  }

  /// "8 glasses", "1 time" — the unit after a count.
  static String unit(int target, String unit) {
    if (unit.isEmpty) return target == 1 ? 'time' : 'times';
    return unit;
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Calendar-day arithmetic. [Duration]-based maths subtracts absolute hours,
  /// which lands on 23:00 of the previous date across a DST change.
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int diffDays(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Inverse of [dateKey]. Returns null for a key this app never wrote.
  static DateTime? parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
