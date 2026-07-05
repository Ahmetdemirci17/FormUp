class DailyStats {
  final double quota;
  final double consumed;
  final double burned;
  final double netRemaining;
  final double protein;
  final double carbs;
  final double fat;
  final double bmr;
  final double tdee;

  const DailyStats({
    required this.quota,
    required this.consumed,
    required this.burned,
    required this.netRemaining,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.bmr,
    required this.tdee,
  });

  double get effectiveQuota => quota + burned;

  double get progress => effectiveQuota > 0 ? consumed / effectiveQuota : 0;
}

class DayCaloriePoint {
  final DateTime date;
  final double consumed;
  final double quota;

  const DayCaloriePoint({
    required this.date,
    required this.consumed,
    required this.quota,
  });
}
