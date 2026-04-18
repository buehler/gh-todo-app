import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/models/authenticated_user_snapshot.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/app_logger_service.dart';
import 'package:gh_todos/services/auth_metadata_storage_service.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/services/session_prefs_service.dart';
import 'package:hive_ce/hive.dart';

Future<ProjectStorageService> createTestProjectStorage() async {
  return ProjectStorageService(_InMemoryStringBox());
}

typedef TestHarness = ({
  ProviderContainer container,
  FakeFlutterSecureStorage storage,
  FakeSessionPrefsService sessionPrefs,
  ProjectStorageService projectStorage,
  FakeAuthMetadataStorageService authMetadataStorage,
  AppLogStore logStore,
});

Future<TestHarness> createTestContainer({
  Map<String, String>? tokenSeed,
  bool throwOnWrite = false,
  PatAuthMetadata? authMetadata,
  GithubAuthService? githubAuth,
}) async {
  final fakeStorage = FakeFlutterSecureStorage(
    seed: tokenSeed,
    throwOnWrite: throwOnWrite,
  );
  final sessionPrefs = FakeSessionPrefsService();
  final projectStorage = await createTestProjectStorage();
  final authMetadataStorage = FakeAuthMetadataStorageService(
    initialValue: authMetadata,
  );
  final logStore = AppLogStore(sinkFactory: () => MemoryAppLogSink());

  final container = ProviderContainer(
    overrides: [
      hiveBootstrapProvider.overrideWith((_) async {}),
      offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
      appLogStoreProvider.overrideWithValue(logStore),
      tokenStorageProvider.overrideWithValue(
        GithubTokenStorageService(storage: fakeStorage),
      ),
      projectStorageProvider.overrideWithValue(projectStorage),
      sessionPrefsProvider.overrideWithValue(sessionPrefs),
      authMetadataStorageProvider.overrideWithValue(authMetadataStorage),
      githubAuthProvider.overrideWithValue(
        githubAuth ??
            FakeGithubAuthService(
              metadata: authMetadata ?? _defaultAuthMetadata,
            ),
      ),
    ],
  );

  return (
    container: container,
    storage: fakeStorage,
    sessionPrefs: sessionPrefs,
    projectStorage: projectStorage,
    authMetadataStorage: authMetadataStorage,
    logStore: logStore,
  );
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
  PatAuthMetadata? authMetadata,
  GithubAuthService? githubAuth,
}) async {
  final fakeStorage = FakeFlutterSecureStorage(
    seed: tokenSeed,
    throwOnWrite: throwOnWrite,
  );
  final sessionPrefs = FakeSessionPrefsService();
  final projectStorage = await createTestProjectStorage();
  final authMetadataStorage = FakeAuthMetadataStorageService(
    initialValue: authMetadata,
  );
  final logStore = AppLogStore(sinkFactory: () => MemoryAppLogSink());

  final app = ProviderScope(
    overrides: [
      hiveBootstrapProvider.overrideWith((_) async {}),
      offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
      appLogStoreProvider.overrideWithValue(logStore),
      tokenStorageProvider.overrideWithValue(
        GithubTokenStorageService(storage: fakeStorage),
      ),
      projectStorageProvider.overrideWithValue(projectStorage),
      sessionPrefsProvider.overrideWithValue(sessionPrefs),
      authMetadataStorageProvider.overrideWithValue(authMetadataStorage),
      githubAuthProvider.overrideWithValue(
        githubAuth ??
            FakeGithubAuthService(
              metadata: authMetadata ?? _defaultAuthMetadata,
            ),
      ),
    ],
    child: GhTodosApp(initialLocation: initialLocation),
  );

  return (app: app, storage: fakeStorage);
}

class FakeSessionPrefsService implements SessionPrefsService {
  String? _selectedProjectId;

  FakeSessionPrefsService({String? selectedProjectId})
    : _selectedProjectId = selectedProjectId;

  @override
  Future<void> clearSelectedProjectId() async {
    _selectedProjectId = null;
  }

  @override
  Future<String?> readSelectedProjectId() async => _selectedProjectId;

  @override
  Future<void> saveSelectedProjectId(String id) async {
    _selectedProjectId = id;
  }
}

class FakeAuthMetadataStorageService implements AuthMetadataStorageService {
  PatAuthMetadata? _value;

  FakeAuthMetadataStorageService({PatAuthMetadata? initialValue})
    : _value = initialValue;

  @override
  Future<void> clear() async {
    _value = null;
  }

  @override
  Future<PatAuthMetadata?> read() async => _value;

  @override
  Future<void> save(PatAuthMetadata metadata) async {
    _value = metadata;
  }
}

class FakeGithubAuthService extends GithubAuthService {
  final PatAuthMetadata metadata;

  FakeGithubAuthService({required this.metadata});

  @override
  Future<PatAuthMetadata> inspectToken(String token) async => metadata;
}

final _defaultAuthMetadata = PatAuthMetadata(
  user: const AuthenticatedUserSnapshot(
    id: '1',
    login: 'me',
    name: 'Test User',
    avatarUrl: 'https://example.com/avatar.png',
  ),
  scopes: const ['project', 'repo', 'read:org'],
  validatedAt: DateTime(2026, 4, 17),
);

class _FakeOfflineStatus extends OfflineStatus {
  @override
  Future<bool> build() async => false;
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

class _InMemoryStringBox implements Box<String> {
  final Map<dynamic, String> _values = {};

  @override
  bool containsKey(dynamic key) => _values.containsKey(key);

  @override
  Future<int> clear() async {
    final count = _values.length;
    _values.clear();
    return count;
  }

  @override
  Future<void> delete(dynamic key) async {
    _values.remove(key);
  }

  @override
  Future<void> put(dynamic key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> putAll(Map<dynamic, String> entries) async {
    _values.addAll(entries);
  }

  @override
  Iterable<String> get values => _values.values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
