import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('inspectToken rejects tokens that are missing read:org', () async {
    final service = GithubAuthService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': '1',
            'login': 'alpha',
            'name': 'Alpha',
            'avatar_url': 'https://example.com/a.png',
          }),
          200,
          headers: {'x-oauth-scopes': 'project, repo'},
        );
      }),
    );

    await expectLater(
      () => service.inspectToken('token-a'),
      throwsA(
        isA<MissingGithubScopesException>().having(
          (error) => error.missingScopes,
          'missingScopes',
          ['read:org'],
        ),
      ),
    );
  });
}
