import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/style/themes.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('shell identity follows auth metadata after PAT update', (
    tester,
  ) async {
    final harness = await createTestContainer(
      githubAuth: GithubAuthService(
        client: MockClient((request) async {
          final token = request.headers['Authorization']?.replaceFirst(
            'Bearer ',
            '',
          );
          final payload = switch (token) {
            'token-a' => _userPayload(id: 'user-a', login: 'alpha'),
            'token-b' => _userPayload(id: 'user-b', login: 'bravo'),
            _ => null,
          };

          if (payload == null) {
            return http.Response('{"message":"Bad credentials"}', 401);
          }

          return http.Response(
            jsonEncode(payload),
            200,
            headers: {
              'x-oauth-scopes': PatAuthMetadata.requiredScopes.join(', '),
            },
          );
        }),
      ),
    );
    addTearDown(harness.container.dispose);

    final session = harness.container.read(sessionProvider.notifier);
    await session.connectToken('token-a');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: MaterialApp(
          home: octanePrime(
            Scaffold(appBar: const AppTopBar(), body: const SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _drainTestExceptions(tester);

    expect(find.text('alpha user'), findsOneWidget);
    expect(find.text('bravo user'), findsNothing);

    await session.updateToken('token-b');
    await tester.pumpAndSettle();
    _drainTestExceptions(tester);

    expect(find.text('bravo user'), findsOneWidget);
    expect(find.text('alpha user'), findsNothing);
  });
}

Map<String, Object?> _userPayload({required String id, required String login}) {
  return {
    'id': id,
    'login': login,
    'name': '$login user',
    'avatar_url': 'https://example.com/$login.png',
  };
}

void _drainTestExceptions(WidgetTester tester) {
  while (tester.takeException() != null) {}
}
