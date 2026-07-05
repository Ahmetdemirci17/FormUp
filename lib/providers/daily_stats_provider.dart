import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_stats.dart';
import '../services/calorie_calculator.dart';
import '../services/database_helper.dart';
import 'refresh_provider.dart';

final dailyStatsProvider = FutureProvider.family<DailyStats, DateTime>((ref, date) async {
  ref.watch(refreshProvider);

  final profile = await DatabaseHelper.instance.getProfile();
  if (profile == null) {
    throw StateError('Profil bulunamadı');
  }

  final foods = await DatabaseHelper.instance.getFoodsByDate(date);
  final activities = await DatabaseHelper.instance.getActivitiesByDate(date);
  final calculation = CalorieCalculator.calculate(profile);

  final consumed = foods.fold<double>(0, (sum, item) => sum + item.calories);
  final burned = activities.fold<double>(0, (sum, item) => sum + item.caloriesBurned);
  final protein = foods.fold<double>(0, (sum, item) => sum + item.protein);
  final carbs = foods.fold<double>(0, (sum, item) => sum + item.carbs);
  final fat = foods.fold<double>(0, (sum, item) => sum + item.fat);

  final effectiveQuota = calculation.dailyQuota + burned;
  final netRemaining = effectiveQuota - consumed;

  return DailyStats(
    quota: calculation.dailyQuota,
    consumed: consumed,
    burned: burned,
    netRemaining: netRemaining,
    protein: protein,
    carbs: carbs,
    fat: fat,
    bmr: calculation.bmr,
    tdee: calculation.tdee,
  );
});
