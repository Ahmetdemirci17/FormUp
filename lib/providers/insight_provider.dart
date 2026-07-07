import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/insight.dart';
import '../services/insight_analyzer.dart';
import 'refresh_provider.dart';

final insightRefreshProvider = StateProvider<int>((ref) => 0);

final insightMessagesProvider = FutureProvider<List<InsightMessage>>((ref) async {
  ref.watch(refreshProvider);
  final forced = ref.watch(insightRefreshProvider) > 0;
  return InsightAnalyzer().getInsights(forceRefresh: forced);
});

void refreshInsights(WidgetRef ref) {
  ref.read(insightRefreshProvider.notifier).state++;
}
