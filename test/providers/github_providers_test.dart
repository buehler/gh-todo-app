import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fake_github_graphql.dart';
import '../support/fakes.dart';

void main() {
  test('account-scoped GitHub providers refetch on PAT change', () async {
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

    final userA = await _readNextValue(harness.container, userInfoProvider);
    final orgsA = await _readNextValue(
      harness.container,
      userOrganizationsProvider,
    );
    final projectsA = await _readNextValue(
      harness.container,
      ownerProjectsProvider('user-a'),
    );

    expect(userA?.login, 'alpha');
    expect(orgsA.map((org) => org.login), ['alpha-org']);
    expect(_projectTitles(projectsA), ['Alpha Personal Board']);

    await session.updateToken('token-b');

    final userB = await _readNextValue(harness.container, userInfoProvider);
    final orgsB = await _readNextValue(
      harness.container,
      userOrganizationsProvider,
    );
    final oldOwnerProjects = await _readNextValue(
      harness.container,
      ownerProjectsProvider('user-a'),
    );
    final newOwnerProjects = await _readNextValue(
      harness.container,
      ownerProjectsProvider('user-b'),
    );

    expect(userB?.login, 'bravo');
    expect(orgsB.map((org) => org.login), ['bravo-org']);
    expect(oldOwnerProjects, isNull);
    expect(_projectTitles(newOwnerProjects), ['Bravo Personal Board']);
  });
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

Future<T> _readNextValue<T>(ProviderContainer container, dynamic provider) {
  final completer = Completer<T>();
  late final dynamic sub;
  sub = container.listen(provider, (_, next) {
    if (next case AsyncData(:final value)) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
      sub.close();
      return;
    }

    if (next case AsyncError(:final error, :final stackTrace)) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      sub.close();
    }
  }, fireImmediately: true);
  return completer.future;
}

List<String> _projectTitles(Query$OwnerProjects$node? node) {
  if (node is Query$OwnerProjects$node$$User) {
    return node.projectsV2.nodes
            ?.whereType<Query$OwnerProjects$node$$User$projectsV2$nodes>()
            .map((project) => project.title)
            .toList() ??
        const [];
  }

  if (node is Query$OwnerProjects$node$$Organization) {
    return node.projectsV2.nodes
            ?.whereType<
              Query$OwnerProjects$node$$Organization$projectsV2$nodes
            >()
            .map((project) => project.title)
            .toList() ??
        const [];
  }

  return const [];
}
