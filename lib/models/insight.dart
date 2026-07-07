import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum InsightType {
  mealCalories,
  calorieTrend,
  calorieTarget,
  proteinBalance,
  weekdayPattern;

  IconData get icon => switch (this) {
        InsightType.mealCalories => Icons.restaurant_menu_rounded,
        InsightType.calorieTrend => Icons.trending_up_rounded,
        InsightType.calorieTarget => Icons.flag_rounded,
        InsightType.proteinBalance => Icons.fitness_center_rounded,
        InsightType.weekdayPattern => Icons.calendar_month_rounded,
      };

  Color get color => switch (this) {
        InsightType.mealCalories => AppColors.primary,
        InsightType.calorieTrend => AppColors.primaryLight,
        InsightType.calorieTarget => AppColors.success,
        InsightType.proteinBalance => AppColors.primaryDark,
        InsightType.weekdayPattern => AppColors.warning,
      };
}

class InsightData {
  final InsightType type;
  final String title;
  final Map<String, Object?> values;
  final double severity;

  const InsightData({
    required this.type,
    required this.title,
    required this.values,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'values': values,
        'severity': severity,
      };
}

class InsightMessage {
  final InsightType type;
  final String text;

  const InsightMessage({required this.type, required this.text});

  factory InsightMessage.fromJson(Map<String, dynamic> json) {
    return InsightMessage(
      type: InsightType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => InsightType.calorieTarget,
      ),
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
      };
}

class InsightCache {
  final DateTime generatedAt;
  final List<InsightMessage> messages;

  const InsightCache({required this.generatedAt, required this.messages});

  factory InsightCache.fromMap(Map<String, dynamic> map) {
    return InsightCache(
      generatedAt: DateTime.parse(map['generatedAt'] as String),
      messages: (map['messages'] as List<dynamic>? ?? [])
          .map((item) => InsightMessage.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((message) => message.text.trim().isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'generatedAt': generatedAt.toIso8601String(),
        'messages': messages.map((message) => message.toJson()).toList(),
      };
}
