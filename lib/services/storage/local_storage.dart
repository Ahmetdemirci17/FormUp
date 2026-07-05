import 'app_data.dart';

abstract class LocalStorage {
  Future<void> init();
  Future<AppData> load();
  Future<void> save(AppData data);
}
