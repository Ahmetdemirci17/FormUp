import 'enums.dart';
import '../utils/date_utils.dart';

class FoodEntry {
  final int? id;
  final DateTime date;
  final MealType mealType;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      mealType: MealType.fromDb(map['mealType'] as String),
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': dateKey(date),
      'mealType': mealType.name,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  FoodEntry copyWith({
    int? id,
    DateTime? date,
    MealType? mealType,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}
