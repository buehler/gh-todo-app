import 'package:gh_todos/services/app_logger_service.dart';
import 'package:gh_todos/services/auth_metadata_storage_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/services/session_prefs_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_ce/hive.dart';

class SessionResetService {
  final GithubTokenStorageService _tokenStorage;
  final ProjectStorageService _projectStorage;
  final SessionPrefsService _sessionPrefs;
  final AuthMetadataStorageService _authMetadataStorage;
  final AppLogger _logger;

  const SessionResetService({
    required GithubTokenStorageService tokenStorage,
    required ProjectStorageService projectStorage,
    required SessionPrefsService sessionPrefs,
    required AuthMetadataStorageService authMetadataStorage,
    required AppLogger logger,
  }) : _tokenStorage = tokenStorage,
       _projectStorage = projectStorage,
       _sessionPrefs = sessionPrefs,
       _authMetadataStorage = authMetadataStorage,
       _logger = logger;

  Future<void> clearAllLocalData({bool clearToken = true}) async {
    await _logger.info(
      'Clearing local GitHub session state.',
      category: 'session',
    );

    if (Hive.isBoxOpen(HiveStore.defaultBoxName)) {
      await Hive.box<dynamic>(HiveStore.defaultBoxName).clear();
    }
    await _projectStorage.save(const []);
    await _sessionPrefs.clearSelectedProjectId();
    await _authMetadataStorage.clear();
    if (clearToken) {
      await _tokenStorage.clearToken();
    }
    await _logger.clear();
  }
}
