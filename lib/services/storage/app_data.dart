class AppData {
  AppData({
    this.profile,
    List<Map<String, dynamic>>? foods,
    List<Map<String, dynamic>>? activities,
    this.nextFoodId = 1,
    this.nextActivityId = 1,
    this.insightCache,
  })  : foods = foods ?? [],
        activities = activities ?? [];

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> foods;
  List<Map<String, dynamic>> activities;
  int nextFoodId;
  int nextActivityId;
  Map<String, dynamic>? insightCache;

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      profile: json['profile'] as Map<String, dynamic>?,
      foods: (json['foods'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      nextFoodId: json['nextFoodId'] as int? ?? 1,
      nextActivityId: json['nextActivityId'] as int? ?? 1,
      insightCache: json['insightCache'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile': profile,
        'foods': foods,
        'activities': activities,
        'nextFoodId': nextFoodId,
        'nextActivityId': nextActivityId,
        'insightCache': insightCache,
      };

  AppData copyWith({
    Map<String, dynamic>? profile,
    bool clearProfile = false,
    List<Map<String, dynamic>>? foods,
    List<Map<String, dynamic>>? activities,
    int? nextFoodId,
    int? nextActivityId,
    Map<String, dynamic>? insightCache,
    bool clearInsightCache = false,
  }) {
    return AppData(
      profile: clearProfile ? null : (profile ?? this.profile),
      foods: foods ?? this.foods,
      activities: activities ?? this.activities,
      nextFoodId: nextFoodId ?? this.nextFoodId,
      nextActivityId: nextActivityId ?? this.nextActivityId,
      insightCache: clearInsightCache ? null : (insightCache ?? this.insightCache),
    );
  }
}
