const months = [
  'yanvar',
  'fevral',
  'mart',
  'aprel',
  'may',
  'iyun',
  'iyul',
  'avgust',
  'sentabr',
  'oktabr',
  'noyabr',
  'dekabr',
];

String som(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer so\'m';
}

String percentText(double value) {
  final fixed = value.toStringAsFixed(1);
  if (fixed.endsWith('.0')) return '${value.toStringAsFixed(0)}%';
  return '$fixed%';
}

String prettyDate(DateTime date) => '${date.day} ${months[date.month - 1]} ${date.year}';

String prettyTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String channelLabel(String channel) {
  switch (channel) {
    case 'olib_ketish':
      return 'Olib ketish';
    case 'yetkazish':
      return 'Yetkazish';
    default:
      return 'Zal';
  }
}

class ReportRange {
  const ReportRange({required this.from, required this.to, required this.label});

  final DateTime from;
  final DateTime to;
  final String label;
}

String currentSeasonKey(DateTime now) {
  if (now.month >= 3 && now.month <= 5) return 'bahor';
  if (now.month >= 6 && now.month <= 8) return 'yoz';
  if (now.month >= 9 && now.month <= 11) return 'kuz';
  return 'qish';
}

ReportRange rangeFor(String key, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (key) {
    case 'week':
      final start = today.subtract(Duration(days: today.weekday - 1));
      return ReportRange(from: start, to: today, label: 'Shu hafta');
    case 'month':
      return ReportRange(from: DateTime(today.year, today.month, 1), to: today, label: 'Shu oy');
    case 'year':
      return ReportRange(from: DateTime(today.year, 1, 1), to: today, label: 'Shu yil');
    case 'bahor':
      return ReportRange(
        from: DateTime(today.year, 3, 1),
        to: DateTime(today.year, 5, 31),
        label: 'Bahor ${today.year}',
      );
    case 'yoz':
      return ReportRange(
        from: DateTime(today.year, 6, 1),
        to: DateTime(today.year, 8, 31),
        label: 'Yoz ${today.year}',
      );
    case 'kuz':
      return ReportRange(
        from: DateTime(today.year, 9, 1),
        to: DateTime(today.year, 11, 30),
        label: 'Kuz ${today.year}',
      );
    case 'qish':
      if (today.month <= 2) {
        final end = DateTime(today.year, 3, 1).subtract(const Duration(days: 1));
        return ReportRange(from: DateTime(today.year - 1, 12, 1), to: end, label: 'Qish ${today.year - 1}');
      }
      final end = DateTime(today.year + 1, 3, 1).subtract(const Duration(days: 1));
      return ReportRange(from: DateTime(today.year, 12, 1), to: end, label: 'Qish ${today.year}');
    case 'today':
    default:
      return ReportRange(from: today, to: today, label: 'Bugun');
  }
}
