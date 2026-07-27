import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/compositions/settings/add_project_sheet.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/style/themes.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fake_github_graphql.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets(
    'add project sheet refreshes after PAT update and adds by username',
    (tester) async {
      Project? selectedProject;
      var userProjectsRequestCount = 0;
      var failNextUserProjectsRequest = true;
      late final TestHarness harness;
      final graphqlClient = createFakeGithubGraphqlClient(
        readToken: () async =>
            harness.container.read(sessionProvider.notifier).readToken(),
        accountsByToken: {'token-a': _accountA, 'token-b': _accountB},
        onOperation: (operationName) {
          if (operationName == 'UserProjects') {
            userProjectsRequestCount++;
          }
        },
        operationError: (operationName, variables) {
          if (operationName == 'UserProjects' && failNextUserProjectsRequest) {
            return GraphQLError(message: 'Injected failure');
          }
          return null;
        },
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
                        onPressed: () async {
                          selectedProject = await showAddProjectSheet(
                            context,
                            excludeProjectIds: const {'project-b-excluded'},
                          );
                        },
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

      await tester.tap(find.text('From another user'));
      await tester.pumpAndSettle();

      expect(find.text('Add from another user'), findsOneWidget);
      expect(find.text('Find projects'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Add Project'), findsOneWidget);
      expect(find.text('Bravo Org Roadmap'), findsOneWidget);

      await tester.tap(find.text('From another user'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), ' @failure ');
      await tester.pump();

      expect(find.text('Could not load projects'), findsNothing);
      expect(userProjectsRequestCount, 0);

      await tester.tap(find.text('Find projects'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load projects'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(userProjectsRequestCount, greaterThan(0));

      final failedRequestCount = userProjectsRequestCount;
      failNextUserProjectsRequest = false;
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Retry Personal Board'), findsOneWidget);
      expect(userProjectsRequestCount, greaterThan(failedRequestCount));

      final retriedRequestCount = userProjectsRequestCount;
      await tester.enterText(find.byType(EditableText), ' @unknown ');
      await tester.pump();
      await tester.tap(find.text('Find projects'));
      await tester.pumpAndSettle();

      expect(find.text('User not found'), findsOneWidget);
      expect(userProjectsRequestCount, retriedRequestCount + 1);

      await tester.enterText(find.byType(EditableText), ' @ghdevcbue2 ');
      await tester.pump();

      expect(find.text('User not found'), findsNothing);
      expect(find.text('Enter a username'), findsOneWidget);

      await tester.tap(find.text('Find projects'));
      await tester.pumpAndSettle();

      expect(find.text('Shared Personal Board'), findsOneWidget);
      expect(userProjectsRequestCount, retriedRequestCount + 2);
      expect(find.text('Already Added Shared Board'), findsNothing);
      expect(find.text('Closed Shared Board'), findsNothing);

      await tester.tap(find.text('Shared Personal Board'));
      await tester.pumpAndSettle();

      expect(selectedProject?.id, 'project-b-shared');
      expect(selectedProject?.ownerLogin, 'GhDevCBue2');
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
  otherUsers: [
    FakeGithubGraphqlUser(
      login: 'failure',
      projects: [
        FakeGithubGraphqlProject(
          id: 'project-b-retry',
          title: 'Retry Personal Board',
        ),
      ],
    ),
    FakeGithubGraphqlUser(
      login: 'GhDevCBue2',
      projects: [
        FakeGithubGraphqlProject(
          id: 'project-b-shared',
          title: 'Shared Personal Board',
        ),
        FakeGithubGraphqlProject(
          id: 'project-b-excluded',
          title: 'Already Added Shared Board',
        ),
        FakeGithubGraphqlProject(
          id: 'project-b-closed',
          title: 'Closed Shared Board',
          closed: true,
        ),
      ],
    ),
  ],
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
