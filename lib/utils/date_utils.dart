String dateKey(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime daysAgo(int days) {
  final now = startOfDay(DateTime.now());
  return now.subtract(Duration(days: days));
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
