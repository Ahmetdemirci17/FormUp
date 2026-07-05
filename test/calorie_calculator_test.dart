import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/models/enums.dart';
import 'package:calorie_tracker/models/user_profile.dart';
import 'package:calorie_tracker/services/calorie_calculator.dart';

void main() {
  const profile = UserProfile(
    gender: Gender.male,
    age: 25,
    heightCm: 175,
    weightKg: 70,
    activityLevel: ActivityLevel.sedentary,
    goalType: GoalType.maintain,
  );

  test('Mifflin-St Jeor BMR for male', () {
    final bmr = CalorieCalculator.calculateBmr(profile);
    expect(bmr, closeTo(10 * 70 + 6.25 * 175 - 5 * 25 + 5, 0.01));
  });

  test('TDEE uses activity multiplier', () {
    const femaleProfile = UserProfile(
      gender: Gender.female,
      age: 30,
      heightCm: 165,
      weightKg: 60,
      activityLevel: ActivityLevel.moderatelyActive,
      goalType: GoalType.maintain,
    );

    final calc = CalorieCalculator.calculate(femaleProfile);
    expect(calc.tdee, closeTo(calc.bmr * 1.55, 0.01));
  });

  test('Weight loss quota uses days-based formula', () {
    const lossProfile = UserProfile(
      gender: Gender.male,
      age: 28,
      heightCm: 180,
      weightKg: 85,
      activityLevel: ActivityLevel.lightlyActive,
      goalType: GoalType.lose,
      goalKg: 5,
      goalDays: 70,
    );

    final calc = CalorieCalculator.calculate(lossProfile);
    final expectedAdjustment = (5 * 7700) / 70;
    expect(calc.dailyAdjustment, closeTo(expectedAdjustment, 0.01));
    expect(calc.dailyQuota, closeTo(calc.tdee - expectedAdjustment, 0.01));
    expect(calc.dailyQuota, lessThan(calc.tdee));
  });

  test('Weekly change rate derived from days', () {
    const lossProfile = UserProfile(
      gender: Gender.male,
      age: 28,
      heightCm: 180,
      weightKg: 85,
      activityLevel: ActivityLevel.lightlyActive,
      goalType: GoalType.lose,
      goalKg: 6,
      goalDays: 60,
    );

    expect(CalorieCalculator.weeklyChangeRateKg(lossProfile), closeTo(0.7, 0.01));
  });

  test('Activity calories include age factor', () {
    const young = UserProfile(
      gender: Gender.male,
      age: 25,
      heightCm: 175,
      weightKg: 70,
      activityLevel: ActivityLevel.sedentary,
      goalType: GoalType.maintain,
    );
    const older = UserProfile(
      gender: Gender.male,
      age: 50,
      heightCm: 175,
      weightKg: 70,
      activityLevel: ActivityLevel.sedentary,
      goalType: GoalType.maintain,
    );

    final youngBurn = CalorieCalculator.calculateActivityCalories(
      profile: young,
      type: ActivityType.running,
      durationMinutes: 30,
    );
    final olderBurn = CalorieCalculator.calculateActivityCalories(
      profile: older,
      type: ActivityType.running,
      durationMinutes: 30,
    );

    expect(youngBurn, closeTo(9.8 * 70 * 0.5 * 1.0, 0.01));
    expect(olderBurn, closeTo(9.8 * 70 * 0.5 * 0.94, 0.01));
    expect(olderBurn, lessThan(youngBurn));
  });

  test('Walking from steps uses profile height and weight', () {
    const walkProfile = UserProfile(
      gender: Gender.female,
      age: 32,
      heightCm: 168,
      weightKg: 62,
      activityLevel: ActivityLevel.moderatelyActive,
      goalType: GoalType.maintain,
    );

    final result = CalorieCalculator.calculateWalkingFromSteps(
      profile: walkProfile,
      steps: 10000,
    );

    expect(result.stepLengthM, closeTo(168 * 0.414 / 100, 0.0001));
    expect(result.distanceKm, greaterThan(0));
    expect(result.durationMinutes, greaterThan(0));
    expect(result.calories, greaterThan(0));
  });

  test('Migrates legacy goalWeeks to goalDays', () {
    final migrated = UserProfile.fromMap({
      'gender': 'male',
      'age': 25,
      'heightCm': 175,
      'weightKg': 75,
      'activityLevel': 'moderatelyActive',
      'goalType': 'lose',
      'goalKg': 5,
      'goalWeeks': 10,
    });
    expect(migrated.goalDays, 70);
  });

  test('UserProfile.initial has empty numeric fields', () {
    final initial = UserProfile.initial();
    expect(initial.age, 0);
    expect(initial.heightCm, 0);
    expect(initial.weightKg, 0);
  });
}
