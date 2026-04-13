import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'storage_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) {
  return SharedPreferences.getInstance();
}

@Riverpod(keepAlive: true)
ProjectStorageService projectStorage(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return ProjectStorageService(prefs);
}

@Riverpod(keepAlive: true)
GithubTokenStorageService tokenStorage(Ref ref) {
  return GithubTokenStorageService();
}
