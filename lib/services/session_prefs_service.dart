import 'package:shared_preferences/shared_preferences.dart';

class SessionPrefsService {
  static const selectedProjectIdKey = 'todos.selected_project_id';

  final SharedPreferencesAsync _prefs;

  SessionPrefsService(this._prefs);

  Future<String?> readSelectedProjectId() {
    return _prefs.getString(selectedProjectIdKey);
  }

  Future<void> saveSelectedProjectId(String id) {
    return _prefs.setString(selectedProjectIdKey, id);
  }

  Future<void> clearSelectedProjectId() {
    return _prefs.remove(selectedProjectIdKey);
  }
}
