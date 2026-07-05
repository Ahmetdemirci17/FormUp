import 'package:flutter_riverpod/legacy.dart';

import '../utils/date_utils.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => startOfDay(DateTime.now()));

final refreshProvider = StateProvider<int>((ref) => 0);

void bumpRefresh(dynamic ref) {
  ref.read(refreshProvider.notifier).state++;
}
