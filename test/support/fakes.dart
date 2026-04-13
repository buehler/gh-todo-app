import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProjectStorageService> createTestProjectStorage() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProjectStorageService(prefs);
}

/// Creates a test app wrapped in a [ProviderScope] with overridden providers.
///
/// If [tokenSeed] is provided, the token storage is seeded with the given
/// key-value pairs (use [GithubTokenStorageService.tokenStorageKey] as key).
///
/// Returns the [FakeFlutterSecureStorage] for assertions.
Future<({Widget app, FakeFlutterSecureStorage storage})> createTestApp({
  Map<String, String>? tokenSeed,
  String? initialLocation,
  bool throwOnWrite = false,
}) async {
  final fakeStorage = FakeFlutterSecureStorage(
    seed: tokenSeed,
    throwOnWrite: throwOnWrite,
  );

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final app = ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        GithubTokenStorageService(storage: fakeStorage),
      ),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
    ],
    child: GhTodosApp(initialLocation: initialLocation),
  );

  return (app: app, storage: fakeStorage);
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
