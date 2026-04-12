import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProjectStorageService> createTestProjectStorage() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProjectStorageService(prefs);
}

class FakeFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _values;
  final bool throwOnWrite;

  FakeFlutterSecureStorage({
    Map<String, String>? seed,
    this.throwOnWrite = false,
  }) : _values = Map<String, String>.from(seed ?? const {});

  Map<String, String> get values => _values;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwOnWrite) {
      throw Exception('write failed');
    }

    if (value == null) {
      _values.remove(key);
      return;
    }

    _values[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _values[key];
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _values.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }
}
