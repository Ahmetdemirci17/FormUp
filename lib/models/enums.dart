enum Gender {
  male,
  female;

  String get label => switch (this) {
        Gender.male => 'Erkek',
        Gender.female => 'Kadın',
      };

  static Gender fromDb(String value) => switch (value) {
        'female' => Gender.female,
        _ => Gender.male,
      };

  String get dbValue => name;
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive;

  String get label => switch (this) {
        ActivityLevel.sedentary => 'Hareketsiz',
        ActivityLevel.lightlyActive => 'Az aktif',
        ActivityLevel.moderatelyActive => 'Orta aktif',
        ActivityLevel.veryActive => 'Çok aktif',
        ActivityLevel.extraActive => 'Ekstra aktif',
      };

  double get multiplier => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.lightlyActive => 1.375,
        ActivityLevel.moderatelyActive => 1.55,
        ActivityLevel.veryActive => 1.725,
        ActivityLevel.extraActive => 1.9,
      };

  static ActivityLevel fromDb(String value) {
    return ActivityLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityLevel.sedentary,
    );
  }
}

enum GoalType {
  lose,
  maintain,
  gain;

  String get label => switch (this) {
        GoalType.lose => 'Kilo ver',
        GoalType.maintain => 'Korumak',
        GoalType.gain => 'Kilo al',
      };

  static GoalType fromDb(String value) {
    return GoalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalType.maintain,
    );
  }
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
        MealType.breakfast => 'Kahvaltı',
        MealType.lunch => 'Öğle',
        MealType.dinner => 'Akşam',
        MealType.snack => 'Atıştırmalık',
      };

  static MealType fromDb(String value) {
    return MealType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MealType.breakfast,
    );
  }
}

enum ActivityType {
  walking,
  running,
  gym,
  cycling,
  swimming;

  String get label => switch (this) {
        ActivityType.walking => 'Yürüyüş',
        ActivityType.running => 'Koşu',
        ActivityType.gym => 'Spor salonu',
        ActivityType.cycling => 'Bisiklet',
        ActivityType.swimming => 'Yüzme',
      };

  double get metValue => switch (this) {
        ActivityType.walking => 3.5,
        ActivityType.running => 9.8,
        ActivityType.gym => 6.0,
        ActivityType.cycling => 7.5,
        ActivityType.swimming => 8.0,
      };

  static ActivityType fromDb(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityType.walking,
    );
  }
}
