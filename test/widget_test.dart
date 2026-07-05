import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:calorie_tracker/app.dart';
import 'package:calorie_tracker/services/database_helper.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    DatabaseHelper.instance.useInMemoryStorageForTesting();
    await DatabaseHelper.instance.init();
    await tester.pumpWidget(
      const ProviderScope(child: CalorieTrackerApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CalorieTrackerApp), findsOneWidget);
  });
}
