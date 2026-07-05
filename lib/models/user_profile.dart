import 'enums.dart';

class UserProfile {
  final int? id;
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final double goalKg;
  final int goalDays;

  const UserProfile({
    this.id,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalType,
    this.goalKg = 0,
    this.goalDays = 0,
  });

  factory UserProfile.initial() => const UserProfile(
        gender: Gender.male,
        age: 0,
        heightCm: 0,
        weightKg: 0,
        activityLevel: ActivityLevel.moderatelyActive,
        goalType: GoalType.maintain,
        goalKg: 0,
        goalDays: 0,
      );

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final legacyWeeks = map['goalWeeks'] as int?;
    final goalDays = map['goalDays'] as int? ??
        (legacyWeeks != null && legacyWeeks > 0 ? legacyWeeks * 7 : 0);

    return UserProfile(
      id: map['id'] as int?,
      gender: Gender.fromDb(map['gender'] as String),
      age: map['age'] as int,
      heightCm: (map['heightCm'] as num).toDouble(),
      weightKg: (map['weightKg'] as num).toDouble(),
      activityLevel: ActivityLevel.fromDb(map['activityLevel'] as String),
      goalType: GoalType.fromDb(map['goalType'] as String),
      goalKg: (map['goalKg'] as num?)?.toDouble() ?? 0,
      goalDays: goalDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'gender': gender.dbValue,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.name,
      'goalType': goalType.name,
      'goalKg': goalKg,
      'goalDays': goalDays,
    };
  }

  UserProfile copyWith({
    int? id,
    Gender? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    GoalType? goalType,
    double? goalKg,
    int? goalDays,
  }) {
    return UserProfile(
      id: id ?? this.id,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      goalKg: goalKg ?? this.goalKg,
      goalDays: goalDays ?? this.goalDays,
    );
  }
}
