import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/services/app_logger_service.dart';
import 'package:gh_todos/services/auth_metadata_storage_service.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/session_reset_service.dart';

class SessionManager {
  final GithubTokenStorageService _tokenStorage;
  final AuthMetadataStorageService _authMetadataStorage;
  final GithubAuthService _authService;
  final SessionResetService _resetService;
  final AppLogger _logger;

  const SessionManager({
    required GithubTokenStorageService tokenStorage,
    required AuthMetadataStorageService authMetadataStorage,
    required GithubAuthService authService,
    required SessionResetService resetService,
    required AppLogger logger,
  }) : _tokenStorage = tokenStorage,
       _authMetadataStorage = authMetadataStorage,
       _authService = authService,
       _resetService = resetService,
       _logger = logger;

  Future<PatAuthMetadata> connectToken(String token) async {
    await _logger.info(
      'Validating token during setup.',
      category: 'session',
    );
    final metadata = await _authService.inspectToken(token);
    await _tokenStorage.saveToken(token);
    await _authMetadataStorage.save(metadata);
    await _logger.info(
      'Token saved for authenticated user ${metadata.user.login}.',
      category: 'session',
    );
    return metadata;
  }

  Future<PatAuthMetadata> updateToken(String token) async {
    await _logger.info(
      'Validating replacement token.',
      category: 'session',
    );

    final currentMetadata = await _authMetadataStorage.read();
    final nextMetadata = await _authService.inspectToken(token);
    final sameUser =
        currentMetadata != null &&
        currentMetadata.user.id == nextMetadata.user.id;

    if (!sameUser) {
      await _logger.warn(
        'Replacement token belongs to a different authenticated user. Purging local state.',
        category: 'session',
      );
      await _resetService.clearAllLocalData(clearToken: true);
    }

    await _tokenStorage.saveToken(token);
    await _authMetadataStorage.save(nextMetadata);

    await _logger.info(
      'Token update completed for ${nextMetadata.user.login}.',
      category: 'session',
    );
    return nextMetadata;
  }

  Future<void> clearSessionData() async {
    await _resetService.clearAllLocalData(clearToken: true);
  }
}
