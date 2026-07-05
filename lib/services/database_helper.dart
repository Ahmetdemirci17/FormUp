import '../models/activity_entry.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../utils/date_utils.dart';
import 'storage/app_data.dart';
import 'storage/in_memory_local_storage.dart';
import 'storage/local_storage.dart';
import 'storage/local_storage_platform.dart' as platform;

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  LocalStorage? _testStorage;
  late LocalStorage _storage;
  AppData _data = AppData();
  bool _initialized = false;

  /// Test ortamında dosya/path_provider kullanmadan bellek içi depolama.
  void useInMemoryStorageForTesting() {
    _testStorage = InMemoryLocalStorage();
    _initialized = false;
  }

  Future<void> init() async {
    if (_initialized) return;
    _storage = _testStorage ?? platform.createLocalStorage();
    await _storage.init();
    _data = await _storage.load();
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  Future<void> _persist() async {
    await _storage.save(_data);
  }

  // --- Profile CRUD ---

  Future<int> saveProfile(UserProfile profile) async {
    await _ensureInit();
    final map = profile.toMap();
    map['id'] = 1;
    _data = _data.copyWith(profile: map);
    await _persist();
    return 1;
  }

  Future<UserProfile?> getProfile() async {
    await _ensureInit();
    final profile = _data.profile;
    if (profile == null) return null;
    return UserProfile.fromMap(profile);
  }

  Future<int> deleteProfile() async {
    await _ensureInit();
    _data = _data.copyWith(clearProfile: true);
    await _persist();
    return 1;
  }

  // --- Food CRUD ---

  Future<int> insertFood(FoodEntry entry) async {
    await _ensureInit();
    final id = _data.nextFoodId;
    final map = entry.toMap()..['id'] = id;
    _data.foods.add(map);
    _data.nextFoodId = id + 1;
    await _persist();
    return id;
  }

  Future<int> updateFood(FoodEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('FoodEntry id is required for update');
    }
    await _ensureInit();
    final index = _data.foods.indexWhere((f) => f['id'] == entry.id);
    if (index == -1) return 0;
    _data.foods[index] = entry.toMap();
    await _persist();
    return 1;
  }

  Future<int> deleteFood(int id) async {
    await _ensureInit();
    final before = _data.foods.length;
    _data.foods.removeWhere((f) => f['id'] == id);
    await _persist();
    return before - _data.foods.length;
  }

  Future<FoodEntry?> getFoodById(int id) async {
    await _ensureInit();
    for (final map in _data.foods) {
      if (map['id'] == id) return FoodEntry.fromMap(map);
    }
    return null;
  }

  Future<List<FoodEntry>> getFoodsByDate(DateTime date) async {
    await _ensureInit();
    final key = dateKey(date);
    return _data.foods
        .where((f) => f['date'] == key)
        .map(FoodEntry.fromMap)
        .toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  }

  Future<List<FoodEntry>> getFoodsInDateRange(DateTime start, DateTime end) async {
    await _ensureInit();
    final startKey = dateKey(start);
    final endKey = dateKey(end);
    return _data.foods
        .where((f) {
          final d = f['date'] as String;
          return d.compareTo(startKey) >= 0 && d.compareTo(endKey) <= 0;
        })
        .map(FoodEntry.fromMap)
        .toList()
      ..sort((a, b) {
        final dateCmp = dateKey(a.date).compareTo(dateKey(b.date));
        if (dateCmp != 0) return dateCmp;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });
  }

  // --- Activity CRUD ---

  Future<int> insertActivity(ActivityEntry entry) async {
    await _ensureInit();
    final id = _data.nextActivityId;
    final map = entry.toMap()..['id'] = id;
    _data.activities.add(map);
    _data.nextActivityId = id + 1;
    await _persist();
    return id;
  }

  Future<int> updateActivity(ActivityEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('ActivityEntry id is required for update');
    }
    await _ensureInit();
    final index = _data.activities.indexWhere((a) => a['id'] == entry.id);
    if (index == -1) return 0;
    _data.activities[index] = entry.toMap();
    await _persist();
    return 1;
  }

  Future<int> deleteActivity(int id) async {
    await _ensureInit();
    final before = _data.activities.length;
    _data.activities.removeWhere((a) => a['id'] == id);
    await _persist();
    return before - _data.activities.length;
  }

  Future<ActivityEntry?> getActivityById(int id) async {
    await _ensureInit();
    for (final map in _data.activities) {
      if (map['id'] == id) return ActivityEntry.fromMap(map);
    }
    return null;
  }

  Future<List<ActivityEntry>> getActivitiesByDate(DateTime date) async {
    await _ensureInit();
    final key = dateKey(date);
    return _data.activities
        .where((a) => a['date'] == key)
        .map(ActivityEntry.fromMap)
        .toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  }

  Future<List<ActivityEntry>> getActivitiesInDateRange(DateTime start, DateTime end) async {
    await _ensureInit();
    final startKey = dateKey(start);
    final endKey = dateKey(end);
    return _data.activities
        .where((a) {
          final d = a['date'] as String;
          return d.compareTo(startKey) >= 0 && d.compareTo(endKey) <= 0;
        })
        .map(ActivityEntry.fromMap)
        .toList()
      ..sort((a, b) {
        final dateCmp = dateKey(a.date).compareTo(dateKey(b.date));
        if (dateCmp != 0) return dateCmp;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });
  }
}
