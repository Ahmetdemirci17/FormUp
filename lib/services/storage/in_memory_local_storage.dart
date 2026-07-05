import 'app_data.dart';
import 'local_storage.dart';

class InMemoryLocalStorage implements LocalStorage {
  AppData _cache = AppData();

  @override
  Future<void> init() async {}

  @override
  Future<AppData> load() async => _cache;

  @override
  Future<void> save(AppData data) async {
    _cache = data;
  }
}
