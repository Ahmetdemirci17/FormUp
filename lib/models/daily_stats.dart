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
  final double breakfast;
  final double lunch;
  final double dinner;
  final double snack;
  final double protein;
  final double carbs;
  final double fat;

  const DayCaloriePoint({
    required this.date,
    required this.consumed,
    required this.quota,
    this.breakfast = 0,
    this.lunch = 0,
    this.dinner = 0,
    this.snack = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  double get macroTotal => protein + carbs + fat;
  double get proteinRatio => macroTotal > 0 ? protein / macroTotal * 100 : 0;
  double get carbsRatio => macroTotal > 0 ? carbs / macroTotal * 100 : 0;
  double get fatRatio => macroTotal > 0 ? fat / macroTotal * 100 : 0;
}

class StatisticsChartData {
  final List<DayCaloriePoint> points;
  final String? weightProjectionText;

  const StatisticsChartData({
    required this.points,
    this.weightProjectionText,
  });
}
