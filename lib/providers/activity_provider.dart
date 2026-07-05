import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_entry.dart';
import '../services/database_helper.dart';
import 'refresh_provider.dart';

final activitiesByDateProvider = FutureProvider.family<List<ActivityEntry>, DateTime>((ref, date) async {
  ref.watch(refreshProvider);
  return DatabaseHelper.instance.getActivitiesByDate(date);
});
