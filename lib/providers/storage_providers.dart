import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/services/session_prefs_service.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hive_bootstrap_provider.dart';

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
ProjectStorageService projectStorage(Ref ref) {
  ref.watch(hiveBootstrapProvider).requireValue;
  return ProjectStorageService(Hive.box<String>(ProjectStorageService.boxName));
}

@Riverpod(keepAlive: true)
GithubTokenStorageService tokenStorage(Ref ref) {
  return GithubTokenStorageService();
}
