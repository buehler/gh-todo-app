import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/services/auth_metadata_storage_service.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/session_reset_service.dart';
import 'package:logging/logging.dart';

class SessionManager {
  static final _logger = Logger('SessionManager');

  final GithubTokenStorageService _tokenStorage;
  final AuthMetadataStorageService _authMetadataStorage;
  final GithubAuthService _authService;
  final SessionResetService _resetService;

  const SessionManager({
    required GithubTokenStorageService tokenStorage,
    required AuthMetadataStorageService authMetadataStorage,
    required GithubAuthService authService,
    required SessionResetService resetService,
  }) : _tokenStorage = tokenStorage,
       _authMetadataStorage = authMetadataStorage,
       _authService = authService,
       _resetService = resetService;

  Future<PatAuthMetadata> connectToken(String token) async {
    _logger.info('Validating token during setup.');
    final metadata = await _authService.inspectToken(token);
    await _tokenStorage.saveToken(token);
    await _authMetadataStorage.save(metadata);
    _logger.info('Token saved for authenticated user ${metadata.user.login}.');
    return metadata;
  }

  Future<PatAuthMetadata> updateToken(String token) async {
    _logger.info('Validating replacement token.');

    final currentMetadata = await _authMetadataStorage.read();
    final nextMetadata = await _authService.inspectToken(token);
    final sameUser =
        currentMetadata != null &&
        currentMetadata.user.id == nextMetadata.user.id;

    if (!sameUser) {
      _logger.warning(
        'Replacement token belongs to a different authenticated user. Purging local state.',
      );
      await _resetService.clearAllLocalData(clearToken: true);
    }

    await _tokenStorage.saveToken(token);
    await _authMetadataStorage.save(nextMetadata);

    _logger.info('Token update completed for ${nextMetadata.user.login}.');
    return nextMetadata;
  }

  Future<void> clearSessionData() async {
    await _resetService.clearAllLocalData(clearToken: true);
  }
}
