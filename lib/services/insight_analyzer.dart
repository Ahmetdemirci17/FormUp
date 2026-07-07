import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/insight.dart';
import '../models/user_profile.dart';
import '../utils/date_utils.dart';
import 'calorie_calculator.dart';
import 'database_helper.dart';

class InsightAnalyzer {
  InsightAnalyzer({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<InsightMessage>> getInsights({bool forceRefresh = false}) async {
    final cached = await DatabaseHelper.instance.getInsightCache();
    final now = DateTime.now();
    if (!forceRefresh && cached != null && _isSameDay(cached.generatedAt, now)) {
      return cached.messages;
    }

    final data = await analyzeRules(days: 30);
    if (data.isEmpty) return [];

    final messages = await _generateNaturalLanguage(data).catchError(
      (_) => _fallbackMessages(data),
    );
    final limitedMessages = messages.take(5).toList();
    await DatabaseHelper.instance.saveInsightCache(
      InsightCache(generatedAt: now, messages: limitedMessages),
    );
    return limitedMessages;
  }

  Future<List<InsightData>> analyzeRules({int days = 30}) async {
    final profile = await DatabaseHelper.instance.getProfile();
    if (profile == null) return [];

    final end = startOfDay(DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    final foods = await DatabaseHelper.instance.getFoodsInDateRange(start, end);
    if (foods.isEmpty) return [];

    final quota = CalorieCalculator.calculateDailyQuota(profile);
    final insights = <InsightData>[];
    insights.addAll(_mealInsights(foods, quota));
    final dailyTotals = _dailyTotals(foods, start, days);
    final recentTotals = dailyTotals.entries.toList().sublist(max(0, dailyTotals.length - 7));
    insights.addAll(_targetInsights(recentTotals, quota));
    final trend = _trendInsight(recentTotals);
    if (trend != null) insights.add(trend);
    final protein = _proteinInsight(foods, profile, days);
    if (protein != null) insights.add(protein);
    final weekday = _weekdayPatternInsight(dailyTotals);
    if (weekday != null) insights.add(weekday);

    insights.sort((a, b) => b.severity.compareTo(a.severity));
    return insights.take(6).toList();
  }

  List<InsightData> _mealInsights(List<FoodEntry> foods, double quota) {
    const shares = {
      MealType.breakfast: 0.25,
      MealType.lunch: 0.35,
      MealType.dinner: 0.30,
      MealType.snack: 0.10,
    };
    final days = foods.map((food) => dateKey(food.date)).toSet().length;
    if (days == 0 || quota <= 0) return [];

    final totals = <MealType, double>{};
    for (final food in foods) {
      totals[food.mealType] = (totals[food.mealType] ?? 0) + food.calories;
    }

    final result = <InsightData>[];
    for (final entry in totals.entries) {
      final avg = entry.value / days;
      final target = quota * (shares[entry.key] ?? 0.25);
      if (target <= 0) continue;
      final deviation = ((avg - target) / target) * 100;
      if (deviation.abs() >= 20) {
        result.add(InsightData(
          type: InsightType.mealCalories,
          title: 'Öğün kalorisi',
          severity: deviation.abs(),
          values: {
            'meal': entry.key.label,
            'averageCalories': avg.round(),
            'deviationPercent': deviation.round(),
          },
        ));
      }
    }
    return result;
  }

  Map<String, double> _dailyTotals(List<FoodEntry> foods, DateTime start, int days) {
    final totals = <String, double>{};
    for (var i = 0; i < days; i++) {
      totals[dateKey(start.add(Duration(days: i)))] = 0;
    }
    for (final food in foods) {
      final key = dateKey(food.date);
      totals[key] = (totals[key] ?? 0) + food.calories;
    }
    return totals;
  }

  List<InsightData> _targetInsights(List<MapEntry<String, double>> dailyTotals, double quota) {
    if (quota <= 0 || dailyTotals.isEmpty) return [];
    final avg = dailyTotals.fold<double>(0, (sum, entry) => sum + entry.value) / dailyTotals.length;
    final diff = avg - quota;
    final deviation = diff / quota * 100;
    if (deviation.abs() < 10) return [];
    return [
      InsightData(
        type: InsightType.calorieTarget,
        title: 'Hedef farkı',
        severity: deviation.abs(),
        values: {
          'days': dailyTotals.length,
          'averageCalories': avg.round(),
          'targetCalories': quota.round(),
          'deviationPercent': deviation.round(),
        },
      ),
    ];
  }

  InsightData? _trendInsight(List<MapEntry<String, double>> dailyTotals) {
    if (dailyTotals.length < 4) return null;
    final values = dailyTotals.map((entry) => entry.value).toList();
    final slope = _linearSlope(values);
    if (slope.abs() < 35) return null;
    return InsightData(
      type: InsightType.calorieTrend,
      title: 'Kalori trendi',
      severity: slope.abs(),
      values: {
        'direction': slope > 0 ? 'artıyor' : 'azalıyor',
        'dailyChangeCalories': slope.round(),
      },
    );
  }

  InsightData? _proteinInsight(List<FoodEntry> foods, UserProfile profile, int days) {
    if (days <= 0 || profile.weightKg <= 0) return null;
    final target = profile.weightKg * 1.6;
    final total = foods.fold<double>(0, (sum, food) => sum + food.protein);
    final avg = total / days;
    final deviation = ((avg - target) / target) * 100;
    if (deviation.abs() < 18) return null;
    return InsightData(
      type: InsightType.proteinBalance,
      title: 'Protein dengesi',
      severity: deviation.abs(),
      values: {
        'averageProtein': avg.round(),
        'targetProtein': target.round(),
        'deviationPercent': deviation.round(),
      },
    );
  }

  InsightData? _weekdayPatternInsight(Map<String, double> dailyTotals) {
    final weekday = <double>[];
    final weekend = <double>[];
    for (final entry in dailyTotals.entries) {
      final date = DateTime.parse(entry.key);
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        weekend.add(entry.value);
      } else {
        weekday.add(entry.value);
      }
    }
    if (weekday.isEmpty || weekend.isEmpty) return null;
    final weekdayAvg = weekday.reduce((a, b) => a + b) / weekday.length;
    final weekendAvg = weekend.reduce((a, b) => a + b) / weekend.length;
    if (weekdayAvg <= 0) return null;
    final deviation = ((weekendAvg - weekdayAvg) / weekdayAvg) * 100;
    if (deviation.abs() < 18) return null;
    return InsightData(
      type: InsightType.weekdayPattern,
      title: 'Hafta deseni',
      severity: deviation.abs(),
      values: {
        'pattern': deviation > 0 ? 'hafta sonu daha yüksek' : 'hafta sonu daha düşük',
        'deviationPercent': deviation.round(),
      },
    );
  }

  double _linearSlope(List<double> values) {
    final n = values.length;
    final meanX = (n - 1) / 2;
    final meanY = values.reduce((a, b) => a + b) / n;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (i - meanX) * (values[i] - meanY);
      denominator += pow(i - meanX, 2).toDouble();
    }
    return denominator == 0 ? 0 : numerator / denominator;
  }

  Future<List<InsightMessage>> _generateNaturalLanguage(List<InsightData> insights) async {
    final apiKey = dotenv.maybeGet('GEMINI_API_KEY')?.trim();
    if (apiKey == null || apiKey.isEmpty) return _fallbackMessages(insights);

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
              {'text': _insightPrompt(insights)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.35,
          'response_mime_type': 'application/json',
        },
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return _fallbackMessages(insights);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return _fallbackMessages(insights);
    final parts = ((candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>? ??
        [];
    final text = parts.map((part) => (part as Map<String, dynamic>)['text']).whereType<String>().join();
    final json = jsonDecode(_stripJsonFence(text)) as Map<String, dynamic>;
    final items = json['insights'] as List<dynamic>? ?? [];
    final messages = <InsightMessage>[];
    for (var i = 0; i < items.length && i < insights.length; i++) {
      final item = Map<String, dynamic>.from(items[i] as Map);
      final text = item['text'] as String? ?? '';
      if (text.trim().isNotEmpty) {
        messages.add(InsightMessage(type: insights[i].type, text: text.trim()));
      }
    }
    return messages.isEmpty ? _fallbackMessages(insights) : messages;
  }

  List<InsightMessage> _fallbackMessages(List<InsightData> insights) {
    return insights.map((insight) {
      final v = insight.values;
      final text = switch (insight.type) {
        InsightType.mealCalories =>
          '${v['meal']} öğününde ortalaman hedef payından yaklaşık %${(v['deviationPercent'] as int).abs()} ${((v['deviationPercent'] as int) > 0) ? 'yüksek' : 'düşük'} görünüyor.',
        InsightType.calorieTarget =>
          'Son ${v['days']} günde günlük ortalaman hedefinden yaklaşık %${(v['deviationPercent'] as int).abs()} ${((v['deviationPercent'] as int) > 0) ? 'yüksek' : 'düşük'}.',
        InsightType.calorieTrend =>
          'Son günlerde kalori alımın günde yaklaşık ${(v['dailyChangeCalories'] as int).abs()} kcal ${v['direction']}.',
        InsightType.proteinBalance =>
          'Protein ortalaman hedefinden yaklaşık %${(v['deviationPercent'] as int).abs()} ${((v['deviationPercent'] as int) > 0) ? 'yüksek' : 'düşük'}; öğünlere biraz daha dengeli yayabilirsin.',
        InsightType.weekdayPattern =>
          'Hafta düzeninde ${v['pattern']} bir kalori deseni var; fark yaklaşık %${(v['deviationPercent'] as int).abs()}.',
      };
      return InsightMessage(type: insight.type, text: text);
    }).toList();
  }

  String _insightPrompt(List<InsightData> insights) {
    return '''
Sen bir beslenme takip asistanısın. Verileri yargılayıcı değil, yapıcı ve destekleyici bir dille özetle.
Tıbbi tavsiye verme; sadece gözlem ve nazik öneri sun. Türkçe yaz.
Her insight için tek kısa cümle üret. Sadece JSON döndür.
Şema: {"insights":[{"text":"..."}]}
Veriler: ${jsonEncode(insights.map((insight) => insight.toJson()).toList())}
''';
  }

  String _stripJsonFence(String value) {
    return value
        .replaceFirst(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'^```\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
