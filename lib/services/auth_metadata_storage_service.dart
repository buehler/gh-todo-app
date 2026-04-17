import 'dart:convert';

import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMetadataStorageService {
  static const metadataStorageKey = 'github.auth_metadata';

  final SharedPreferencesAsync _prefs;

  AuthMetadataStorageService(this._prefs);

  Future<PatAuthMetadata?> read() async {
    final raw = await _prefs.getString(metadataStorageKey);
    if (raw == null || raw.isEmpty) return null;

    return PatAuthMetadata.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(PatAuthMetadata metadata) {
    return _prefs.setString(metadataStorageKey, jsonEncode(metadata.toJson()));
  }

  Future<void> clear() {
    return _prefs.remove(metadataStorageKey);
  }
}
