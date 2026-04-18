import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/providers/auth_metadata_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

void main() {
  group('Session token replacement', () {
    test(
      'clears local state when replacement token belongs to another user',
      () async {
        final harness = await createTestContainer(
          githubAuth: GithubAuthService(
            client: _mockClientForProfiles({
              'token-a': _userPayload(id: '100', login: 'alpha'),
              'token-b': _userPayload(id: '200', login: 'bravo'),
            }),
          ),
        );
        addTearDown(harness.container.dispose);

        final session = harness.container.read(sessionProvider.notifier);
        final logger = harness.container.read(appLoggerProvider);

        await session.connectToken('token-a');
        await harness.projectStorage.add(_project());
        await harness.sessionPrefs.saveSelectedProjectId(_projectId);
        await logger.info('seed marker', category: 'test');

        expect(harness.container.read(projectListProvider), [_project()]);
        expect(
          await harness.container.read(selectedProjectProvider.future),
          _projectId,
        );

        await session.updateToken('token-b');

        expect(
          harness.storage.values[GithubTokenStorageService.tokenStorageKey],
          'token-b',
        );
        expect(harness.projectStorage.readAll(), isEmpty);
        expect(await harness.sessionPrefs.readSelectedProjectId(), isNull);
        expect(harness.container.read(projectListProvider), isEmpty);
        expect(
          await harness.container.read(selectedProjectProvider.future),
          isNull,
        );

        final metadata = await harness.container.read(
          authMetadataProvider.future,
        );
        expect(metadata?.user.id, '200');
        expect(metadata?.user.login, 'bravo');

        final logLines = await logger.readLines();
        expect(logLines.any((line) => line.contains('seed marker')), isFalse);
      },
    );

    test(
      'preserves local state when replacement token belongs to the same user',
      () async {
        final harness = await createTestContainer(
          githubAuth: GithubAuthService(
            client: _mockClientForProfiles({
              'token-a': _userPayload(id: '100', login: 'alpha'),
              'token-b': _userPayload(id: '100', login: 'alpha-renewed'),
            }),
          ),
        );
        addTearDown(harness.container.dispose);

        final session = harness.container.read(sessionProvider.notifier);
        final logger = harness.container.read(appLoggerProvider);

        await session.connectToken('token-a');
        await harness.projectStorage.add(_project());
        await harness.sessionPrefs.saveSelectedProjectId(_projectId);
        await logger.info('seed marker', category: 'test');

        expect(harness.container.read(projectListProvider), [_project()]);
        expect(
          await harness.container.read(selectedProjectProvider.future),
          _projectId,
        );

        await session.updateToken('token-b');

        expect(
          harness.storage.values[GithubTokenStorageService.tokenStorageKey],
          'token-b',
        );
        expect(harness.projectStorage.readAll(), [_project()]);
        expect(await harness.sessionPrefs.readSelectedProjectId(), _projectId);
        expect(harness.container.read(projectListProvider), [_project()]);
        expect(
          await harness.container.read(selectedProjectProvider.future),
          _projectId,
        );

        final metadata = await harness.container.read(
          authMetadataProvider.future,
        );
        expect(metadata?.user.id, '100');
        expect(metadata?.user.login, 'alpha-renewed');

        final logLines = await logger.readLines();
        expect(logLines.any((line) => line.contains('seed marker')), isTrue);
      },
    );
  });
}

const _projectId = 'project-1';

Project _project() =>
    const Project(id: _projectId, name: 'Inbox', ownerLogin: 'alpha');

Map<String, Object?> _userPayload({required String id, required String login}) {
  return {
    'id': id,
    'login': login,
    'name': '$login user',
    'avatar_url': 'https://example.com/$login.png',
  };
}

MockClient _mockClientForProfiles(Map<String, Map<String, Object?>> profiles) {
  return MockClient((request) async {
    final auth = request.headers['Authorization'];
    final token = auth?.replaceFirst('Bearer ', '');
    final payload = token != null ? profiles[token] : null;
    if (payload == null) {
      return http.Response('{"message":"Bad credentials"}', 401);
    }

    return http.Response(
      jsonEncode(payload),
      200,
      headers: {'x-oauth-scopes': PatAuthMetadata.requiredScopes.join(', ')},
    );
  });
}
