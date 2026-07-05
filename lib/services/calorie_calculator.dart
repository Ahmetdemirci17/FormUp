import '../models/enums.dart';
import '../models/user_profile.dart';

class CalorieCalculation {
  final double bmr;
  final double tdee;
  final double dailyQuota;
  final double dailyAdjustment;

  const CalorieCalculation({
    required this.bmr,
    required this.tdee,
    required this.dailyQuota,
    required this.dailyAdjustment,
  });
}

class WalkingCalculation {
  final double stepLengthM;
  final double distanceKm;
  final int durationMinutes;
  final double calories;

  const WalkingCalculation({
    required this.stepLengthM,
    required this.distanceKm,
    required this.durationMinutes,
    required this.calories,
  });
}

abstract final class CalorieCalculator {
  static const double kcalPerKgFat = 7700;
  static const double walkingSpeedKmh = 5.0;

  static double calculateBmr(UserProfile profile) {
    final base = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age;
    return profile.gender == Gender.male ? base + 5 : base - 161;
  }

  static double calculateTdee(UserProfile profile) {
    return calculateBmr(profile) * profile.activityLevel.multiplier;
  }

  static double calculateDailyAdjustment(UserProfile profile) {
    if (profile.goalType == GoalType.maintain || profile.goalDays <= 0 || profile.goalKg <= 0) {
      return 0;
    }
    return (profile.goalKg * kcalPerKgFat) / profile.goalDays;
  }

  static double? weeklyChangeRateKg(UserProfile profile) {
    if (profile.goalDays <= 0 || profile.goalKg <= 0) return null;
    return (profile.goalKg / profile.goalDays) * 7;
  }

  static CalorieCalculation calculate(UserProfile profile) {
    final bmr = calculateBmr(profile);
    final tdee = calculateTdee(profile);
    final adjustment = calculateDailyAdjustment(profile);

    final quota = switch (profile.goalType) {
      GoalType.lose => tdee - adjustment,
      GoalType.gain => tdee + adjustment,
      GoalType.maintain => tdee,
    };

    return CalorieCalculation(
      bmr: bmr,
      tdee: tdee,
      dailyQuota: quota,
      dailyAdjustment: adjustment,
    );
  }

  static double calculateDailyQuota(UserProfile profile) {
    return calculate(profile).dailyQuota;
  }

  /// 18-29: 1.00 | 30-44: 0.97 | 45-59: 0.94 | 60+: 0.90
  static double ageFactor(int age) {
    if (age < 30) return 1.00;
    if (age < 45) return 0.97;
    if (age < 60) return 0.94;
    return 0.90;
  }

  static double stepLengthMeters(double heightCm) {
    if (heightCm <= 0) return 0;
    return heightCm * 0.414 / 100;
  }

  static int durationFromDistanceKm(double distanceKm) {
    if (distanceKm <= 0) return 0;
    return ((distanceKm / walkingSpeedKmh) * 60).round();
  }

  static double distanceKmFromSteps({required double heightCm, required int steps}) {
    if (steps <= 0 || heightCm <= 0) return 0;
    final stepLength = stepLengthMeters(heightCm);
    return (steps * stepLength) / 1000;
  }

  static WalkingCalculation calculateWalkingFromSteps({
    required UserProfile profile,
    required int steps,
  }) {
    final stepLength = stepLengthMeters(profile.heightCm);
    final distanceKm = distanceKmFromSteps(heightCm: profile.heightCm, steps: steps);
    final durationMinutes = durationFromDistanceKm(distanceKm);
    final calories = calculateActivityCalories(
      profile: profile,
      type: ActivityType.walking,
      durationMinutes: durationMinutes,
    );
    return WalkingCalculation(
      stepLengthM: stepLength,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      calories: calories,
    );
  }

  static double calculateActivityCalories({
    required UserProfile profile,
    required ActivityType type,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0 || profile.weightKg <= 0 || profile.age <= 0) return 0;
    final factor = ageFactor(profile.age);
    return type.metValue * profile.weightKg * (durationMinutes / 60) * factor;
  }

  static double minimumSafeCalories(Gender gender) {
    return gender == Gender.female ? 1200 : 1500;
  }

  static bool isBelowMinimumSafeCalories(UserProfile profile, double quota) {
    return quota < minimumSafeCalories(profile.gender);
  }

  static bool hasCompleteBodyMetrics(UserProfile profile) {
    return profile.age >= 10 &&
        profile.age <= 100 &&
        profile.heightCm >= 100 &&
        profile.heightCm <= 250 &&
        profile.weightKg >= 30 &&
        profile.weightKg <= 300;
  }
}
