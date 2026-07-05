import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/daily_stats.dart';
import '../services/calorie_calculator.dart';
import '../services/database_helper.dart';
import '../utils/date_utils.dart';
import 'refresh_provider.dart';

final statisticsRangeProvider = StateProvider<int>((ref) => 7);

final statisticsChartProvider = FutureProvider<List<DayCaloriePoint>>((ref) async {
  ref.watch(refreshProvider);
  final rangeDays = ref.watch(statisticsRangeProvider);

  final profile = await DatabaseHelper.instance.getProfile();
  if (profile == null) return [];

  final quota = CalorieCalculator.calculateDailyQuota(profile);
  final end = startOfDay(DateTime.now());
  final start = end.subtract(Duration(days: rangeDays - 1));

  final foods = await DatabaseHelper.instance.getFoodsInDateRange(start, end);
  final totalsByDate = <String, double>{};

  for (final food in foods) {
    final key = dateKey(food.date);
    totalsByDate[key] = (totalsByDate[key] ?? 0) + food.calories;
  }

  final points = <DayCaloriePoint>[];
  for (var i = 0; i < rangeDays; i++) {
    final day = start.add(Duration(days: i));
    final key = dateKey(day);
    points.add(DayCaloriePoint(
      date: day,
      consumed: totalsByDate[key] ?? 0,
      quota: quota,
    ));
  }

  return points;
});
