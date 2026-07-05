import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';
import 'local_storage.dart';

LocalStorage createLocalStorage() => PrefsLocalStorage();

class PrefsLocalStorage implements LocalStorage {
  static const _key = 'calorie_tracker_data';
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<AppData> load() async {
    final prefs = _prefs;
    if (prefs == null) return AppData();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return AppData();
    return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppData data) async {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('PrefsLocalStorage not initialized');
    }
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}
