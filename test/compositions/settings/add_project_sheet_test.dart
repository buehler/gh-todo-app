import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/compositions/settings/add_project_sheet.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/style/themes.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fake_github_graphql.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets(
    'add project sheet refreshes viewer, orgs, and projects after PAT update',
    (tester) async {
      late final TestHarness harness;
      final graphqlClient = createFakeGithubGraphqlClient(
        readToken: () async =>
            harness.container.read(sessionProvider.notifier).readToken(),
        accountsByToken: {'token-a': _accountA, 'token-b': _accountB},
      );

      harness = await createTestContainer(
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
        graphqlClient: graphqlClient,
      );
      addTearDown(harness.container.dispose);

      final session = harness.container.read(sessionProvider.notifier);
      await session.connectToken('token-a');

      final userSub = harness.container.listen(userInfoProvider, (_, _) {});
      final orgsSub = harness.container.listen(
        userOrganizationsProvider,
        (_, _) {},
      );
      final ownerSub = harness.container.listen(
        ownerProjectsProvider('user-a'),
        (_, _) {},
      );
      addTearDown(userSub.close);
      addTearDown(orgsSub.close);
      addTearDown(ownerSub.close);

      await harness.container.read(userInfoProvider.future);
      await harness.container.read(userOrganizationsProvider.future);
      await harness.container.read(ownerProjectsProvider('user-a').future);

      await session.updateToken('token-b');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: octanePrime(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () => showAddProjectSheet(context),
                        child: const Text('Open Add Project'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Add Project'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('bravo'), findsOneWidget);
      expect(find.text('alpha'), findsNothing);
      expect(find.text('Bravo Personal Board'), findsOneWidget);
      expect(find.text('Alpha Personal Board'), findsNothing);

      await tester.tap(find.text('bravo'));
      await tester.pumpAndSettle();

      expect(find.text('bravo-org'), findsOneWidget);
      expect(find.text('alpha-org'), findsNothing);

      await tester.tap(find.text('bravo-org').last);
      await tester.pumpAndSettle();

      expect(find.text('Bravo Org Roadmap'), findsOneWidget);
      expect(find.text('Alpha Org Board'), findsNothing);
    },
  );
}

const _accountA = FakeGithubGraphqlAccount(
  viewer: FakeGithubGraphqlViewer(
    id: 'user-a',
    login: 'alpha',
    name: 'Alpha User',
    avatarUrl: 'https://example.com/alpha.png',
  ),
  organizations: [FakeGithubGraphqlOrg(id: 'org-a', login: 'alpha-org')],
  projectsByOwnerId: {
    'user-a': [
      FakeGithubGraphqlProject(
        id: 'project-a-user',
        title: 'Alpha Personal Board',
      ),
    ],
    'org-a': [
      FakeGithubGraphqlProject(id: 'project-a-org', title: 'Alpha Org Board'),
    ],
  },
);

const _accountB = FakeGithubGraphqlAccount(
  viewer: FakeGithubGraphqlViewer(
    id: 'user-b',
    login: 'bravo',
    name: 'Bravo User',
    avatarUrl: 'https://example.com/bravo.png',
  ),
  organizations: [FakeGithubGraphqlOrg(id: 'org-b', login: 'bravo-org')],
  projectsByOwnerId: {
    'user-b': [
      FakeGithubGraphqlProject(
        id: 'project-b-user',
        title: 'Bravo Personal Board',
      ),
    ],
    'org-b': [
      FakeGithubGraphqlProject(id: 'project-b-org', title: 'Bravo Org Roadmap'),
    ],
  },
);

Map<String, Object?> _userPayload({required String id, required String login}) {
  return {
    'id': id,
    'login': login,
    'name': '$login user',
    'avatar_url': 'https://example.com/$login.png',
  };
}
