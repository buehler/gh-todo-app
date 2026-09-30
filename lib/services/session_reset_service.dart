import 'package:gh_todos/services/app_logging.dart';
import 'package:gh_todos/services/auth_metadata_storage_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/services/session_prefs_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_ce/hive.dart';
import 'package:logging/logging.dart';

class SessionResetService {
  static final _logger = Logger('SessionResetService');

  final GithubTokenStorageService _tokenStorage;
  final ProjectStorageService _projectStorage;
  final SessionPrefsService _sessionPrefs;
  final AuthMetadataStorageService _authMetadataStorage;

  const SessionResetService({
    required GithubTokenStorageService tokenStorage,
    required ProjectStorageService projectStorage,
    required SessionPrefsService sessionPrefs,
    required AuthMetadataStorageService authMetadataStorage,
  }) : _tokenStorage = tokenStorage,
       _projectStorage = projectStorage,
       _sessionPrefs = sessionPrefs,
       _authMetadataStorage = authMetadataStorage;

  Future<void> clearAllLocalData({bool clearToken = true}) async {
    _logger.info('Clearing local GitHub session state.');

    if (Hive.isBoxOpen(HiveStore.defaultBoxName)) {
      await Hive.box<dynamic>(HiveStore.defaultBoxName).clear();
    }
    await _projectStorage.save(const []);
    await _sessionPrefs.clearSelectedProjectId();
    await _authMetadataStorage.clear();
    if (clearToken) {
      await _tokenStorage.clearToken();
    }
    talkerInstance.cleanHistory();
  }
}
