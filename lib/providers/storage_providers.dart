import 'package:gh_todos/services/auth_metadata_storage_service.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/session_manager.dart';
import 'package:gh_todos/services/session_reset_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/services/session_prefs_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';

part 'storage_providers.g.dart';

@Riverpod(keepAlive: true)
SharedPreferencesAsync sharedPreferences(Ref ref) {
  return SharedPreferencesAsync();
}

@Riverpod(keepAlive: true)
SessionPrefsService sessionPrefs(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SessionPrefsService(prefs);
}

@Riverpod(keepAlive: true)
AuthMetadataStorageService authMetadataStorage(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthMetadataStorageService(prefs);
}

@Riverpod(keepAlive: true)
ProjectStorageService projectStorage(Ref ref) {
  ref.watch(hiveBootstrapProvider);
  return ProjectStorageService(Hive.box<String>(ProjectStorageService.boxName));
}

@Riverpod(keepAlive: true)
GithubTokenStorageService tokenStorage(Ref ref) {
  return GithubTokenStorageService();
}

@Riverpod(keepAlive: true)
GithubAuthService githubAuth(Ref ref) {
  return GithubAuthService();
}

@Riverpod(keepAlive: true)
SessionResetService sessionReset(Ref ref) {
  return SessionResetService(
    tokenStorage: ref.watch(tokenStorageProvider),
    projectStorage: ref.watch(projectStorageProvider),
    sessionPrefs: ref.watch(sessionPrefsProvider),
    authMetadataStorage: ref.watch(authMetadataStorageProvider),
    logger: ref.watch(appLoggerProvider),
  );
}

@Riverpod(keepAlive: true)
SessionManager sessionManager(Ref ref) {
  return SessionManager(
    tokenStorage: ref.watch(tokenStorageProvider),
    authMetadataStorage: ref.watch(authMetadataStorageProvider),
    authService: ref.watch(githubAuthProvider),
    resetService: ref.watch(sessionResetProvider),
    logger: ref.watch(appLoggerProvider),
  );
}
