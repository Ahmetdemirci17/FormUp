import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_entry.dart';
import '../services/database_helper.dart';
import 'refresh_provider.dart';

final foodsByDateProvider = FutureProvider.family<List<FoodEntry>, DateTime>((ref, date) async {
  ref.watch(refreshProvider);
  return DatabaseHelper.instance.getFoodsByDate(date);
});
