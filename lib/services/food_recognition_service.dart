import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/recognized_food.dart';

class FoodRecognitionException implements Exception {
  final String message;

  const FoodRecognitionException(this.message);

  @override
  String toString() => message;
}

class FoodRecognitionService {
  FoodRecognitionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RecognizedFood> analyzeImage(File imageFile) async {
    final apiKey = dotenv.maybeGet('GEMINI_API_KEY')?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const FoodRecognitionException(
        'Görsel analiz için GEMINI_API_KEY .env dosyasına eklenmeli.',
      );
    }

    try {
      final aiFood = await _analyzeWithGemini(imageFile, apiKey);
      if (aiFood.isPackagedProduct) {
        final productFood = await _findOpenFoodFactsProduct(aiFood);
        if (productFood != null) return productFood;
      }
      return aiFood;
    } on FoodRecognitionException {
      rethrow;
    } catch (_) {
      throw const FoodRecognitionException(
        'Analiz yapılamadı, manuel giriş yapabilirsiniz.',
      );
    }
  }

  Future<RecognizedFood> _analyzeWithGemini(File imageFile, String apiKey) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _mimeTypeFor(imageFile.path);
    final envModel = dotenv.maybeGet('GEMINI_MODEL')?.trim();
    final model = envModel == null || envModel.isEmpty ? 'gemini-3.5-flash' : envModel;

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': apiKey},
    );

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': _foodPrompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'response_mime_type': 'application/json',
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const FoodRecognitionException(
        'Analiz servisi yanıt vermedi, manuel giriş yapabilirsiniz.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw const FoodRecognitionException('Yemek tanınamadı.');
    }

    final content = candidates.first as Map<String, dynamic>;
    final parts = (content['content'] as Map<String, dynamic>?)?['parts'] as List<dynamic>? ?? [];
    final text = parts
        .map((part) => (part as Map<String, dynamic>)['text'])
        .whereType<String>()
        .join()
        .trim();

    if (text.isEmpty) {
      throw const FoodRecognitionException('Yemek tanınamadı.');
    }

    return RecognizedFood.fromAiJson(jsonDecode(_stripJsonFence(text)) as Map<String, dynamic>);
  }

  Future<RecognizedFood?> _findOpenFoodFactsProduct(RecognizedFood aiFood) async {
    final query = [
      aiFood.brandName,
      aiFood.foodName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

    if (query.trim().isEmpty) return null;

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '1',
      'fields': 'product_name,brands,nutriments',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': dotenv.maybeGet('OPEN_FOOD_FACTS_USER_AGENT') ??
          'FormUp/1.0 (contact@example.com)',
    });

    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final products = decoded['products'] as List<dynamic>? ?? [];
    if (products.isEmpty) return null;

    final product = products.first as Map<String, dynamic>;
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final caloriesPer100g = _num(nutriments['energy-kcal_100g']);
    if (caloriesPer100g <= 0) return null;

    final portionGrams = aiFood.estimatedPortionGrams > 0 ? aiFood.estimatedPortionGrams : 100.0;
    final portionFactor = portionGrams / 100;
    final name = (product['product_name'] as String?)?.trim();
    final brand = (product['brands'] as String?)?.split(',').first.trim();

    return aiFood.copyWith(
      foodName: name?.isNotEmpty == true ? name : aiFood.foodName,
      brandName: brand?.isNotEmpty == true ? brand : aiFood.brandName,
      estimatedPortionGrams: portionGrams,
      calories: caloriesPer100g * portionFactor,
      protein: _num(nutriments['proteins_100g']) * portionFactor,
      carbs: _num(nutriments['carbohydrates_100g']) * portionFactor,
      fat: _num(nutriments['fat_100g']) * portionFactor,
      source: RecognizedFoodSource.productDatabase,
      confidence: 'high',
    );
  }

  String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _stripJsonFence(String value) {
    return value
        .replaceFirst(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'^```\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  double _num(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

const _foodPrompt = '''
Fotoğraftaki yemeği veya paketli ürünü analiz et.
Sadece geçerli JSON döndür, markdown kullanma.
Paketli/markalı ürünse marka/ürün adını yakalamaya çalış.
Ev yemeği veya açık tabaksa porsiyona göre makroları tahmin et.
Şema:
{
  "food_name": "Tavuklu Pilav",
  "is_packaged_product": false,
  "brand_name": null,
  "estimated_portion_grams": 300,
  "calories": 450,
  "protein": 25,
  "carbs": 55,
  "fat": 12,
  "confidence": "medium"
}
''';
