import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/daily_stats.dart';
import '../models/enums.dart';
import '../services/calorie_calculator.dart';
import '../services/database_helper.dart';
import '../utils/date_utils.dart';
import 'refresh_provider.dart';

final statisticsRangeProvider = StateProvider<int>((ref) => 7);

final statisticsChartProvider = FutureProvider<StatisticsChartData>((ref) async {
  ref.watch(refreshProvider);
  final rangeDays = ref.watch(statisticsRangeProvider);

  final profile = await DatabaseHelper.instance.getProfile();
  if (profile == null) return const StatisticsChartData(points: []);

  final quota = CalorieCalculator.calculateDailyQuota(profile);
  final end = startOfDay(DateTime.now());
  final start = end.subtract(Duration(days: rangeDays - 1));

  final foods = await DatabaseHelper.instance.getFoodsInDateRange(start, end);
  final byDate = <String, _DayAccumulator>{};

  for (var i = 0; i < rangeDays; i++) {
    final day = start.add(Duration(days: i));
    byDate[dateKey(day)] = _DayAccumulator(day, quota);
  }

  for (final food in foods) {
    final key = dateKey(food.date);
    final day = byDate[key];
    if (day == null) continue;
    day.consumed += food.calories;
    day.protein += food.protein;
    day.carbs += food.carbs;
    day.fat += food.fat;
    switch (food.mealType) {
      case MealType.breakfast:
        day.breakfast += food.calories;
      case MealType.lunch:
        day.lunch += food.calories;
      case MealType.dinner:
        day.dinner += food.calories;
      case MealType.snack:
        day.snack += food.calories;
    }
  }

  final points = byDate.values.map((day) => day.toPoint()).toList();
  return StatisticsChartData(
    points: points,
    weightProjectionText: _weightProjection(points, profile, quota),
  );
});

String? _weightProjection(List<DayCaloriePoint> points, dynamic profile, double quota) {
  if (profile.goalKg <= 0 || profile.goalType == GoalType.maintain || points.isEmpty) return null;
  final nonEmpty = points.where((point) => point.consumed > 0).toList();
  if (nonEmpty.isEmpty) return null;
  final avgConsumed = nonEmpty.fold<double>(0, (sum, point) => sum + point.consumed) / nonEmpty.length;
  final dailyGap = max(0.0, profile.goalType == GoalType.lose ? quota - avgConsumed : avgConsumed - quota);
  if (dailyGap <= 50) return 'Bu tempoda hedef için belirgin bir günlük kalori farkı oluşmadı.';
  final days = ((profile.goalKg * CalorieCalculator.kcalPerKgFat) / dailyGap).ceil();
  return 'Bu tempoda yaklaşık $days günde hedef kilona ulaşabilirsin.';
}

class _DayAccumulator {
  _DayAccumulator(this.date, this.quota);

  final DateTime date;
  final double quota;
  double consumed = 0;
  double breakfast = 0;
  double lunch = 0;
  double dinner = 0;
  double snack = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;

  DayCaloriePoint toPoint() => DayCaloriePoint(
        date: date,
        consumed: consumed,
        quota: quota,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snack: snack,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
}
