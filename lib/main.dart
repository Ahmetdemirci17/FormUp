import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'services/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // .env geliştirme ortamında opsiyoneldir; anahtar yoksa ilgili özellik uyarı verir.
  }
  await DatabaseHelper.instance.init();
  runApp(const ProviderScope(child: CalorieTrackerApp()));
}
