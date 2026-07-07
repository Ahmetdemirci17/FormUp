enum RecognizedFoodSource {
  productDatabase,
  aiEstimate;

  String get label => switch (this) {
        RecognizedFoodSource.productDatabase => 'Ürün veritabanından bulundu',
        RecognizedFoodSource.aiEstimate => 'AI tahmini',
      };
}

class RecognizedFood {
  final String foodName;
  final bool isPackagedProduct;
  final String? brandName;
  final double estimatedPortionGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String confidence;
  final RecognizedFoodSource source;

  const RecognizedFood({
    required this.foodName,
    required this.isPackagedProduct,
    this.brandName,
    required this.estimatedPortionGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    required this.source,
  });

  factory RecognizedFood.fromAiJson(Map<String, dynamic> json) {
    return RecognizedFood(
      foodName: (json['food_name'] as String?)?.trim().isNotEmpty == true
          ? (json['food_name'] as String).trim()
          : 'Tanınan yemek',
      isPackagedProduct: json['is_packaged_product'] as bool? ?? false,
      brandName: (json['brand_name'] as String?)?.trim(),
      estimatedPortionGrams: _asDouble(json['estimated_portion_grams']),
      calories: _asDouble(json['calories']),
      protein: _asDouble(json['protein']),
      carbs: _asDouble(json['carbs']),
      fat: _asDouble(json['fat']),
      confidence: json['confidence'] as String? ?? 'medium',
      source: RecognizedFoodSource.aiEstimate,
    );
  }

  RecognizedFood copyWith({
    String? foodName,
    bool? isPackagedProduct,
    String? brandName,
    double? estimatedPortionGrams,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? confidence,
    RecognizedFoodSource? source,
  }) {
    return RecognizedFood(
      foodName: foodName ?? this.foodName,
      isPackagedProduct: isPackagedProduct ?? this.isPackagedProduct,
      brandName: brandName ?? this.brandName,
      estimatedPortionGrams: estimatedPortionGrams ?? this.estimatedPortionGrams,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
    );
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
