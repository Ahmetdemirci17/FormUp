import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_data.dart';
import 'local_storage.dart';

LocalStorage createLocalStorage() => FileLocalStorage();

class FileLocalStorage implements LocalStorage {
  static const _fileName = 'calorie_tracker.json';
  File? _file;

  @override
  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _file = File(p.join(dir.path, _fileName));
  }

  @override
  Future<AppData> load() async {
    final file = _file;
    if (file == null || !await file.exists()) {
      return AppData();
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return AppData();
    return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppData data) async {
    final file = _file;
    if (file == null) {
      throw StateError('FileLocalStorage not initialized');
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
    );
  }
}
