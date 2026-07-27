import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:graphql/client.dart';
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

    final userA = await harness.container.read(userInfoProvider.future);
    final orgsA = await harness.container.read(
      userOrganizationsProvider.future,
    );
    final projectsA = await harness.container.read(
      ownerProjectsProvider('user-a').future,
    );

    expect(userA?.login, 'alpha');
    expect(orgsA.map((org) => org.login), ['alpha-org']);
    expect(_projectTitles(projectsA), ['Alpha Personal Board']);
    final userProjectsA = await harness.container.read(
      userProjectsProvider('ghdevcbue2').future,
    );
    expect(userProjectsA?.login, 'GhDevCBue2');
    expect(userProjectsA?.projectsV2.nodes?.map((project) => project?.title), [
      'Shared Personal Board',
    ]);

    await session.updateToken('token-b');

    final userB = await harness.container.read(userInfoProvider.future);
    final orgsB = await harness.container.read(
      userOrganizationsProvider.future,
    );
    final oldOwnerProjects = await harness.container.read(
      ownerProjectsProvider('user-a').future,
    );
    final newOwnerProjects = await harness.container.read(
      ownerProjectsProvider('user-b').future,
    );
    final userProjectsB = await harness.container.read(
      userProjectsProvider('ghdevcbue2').future,
    );

    expect(userB?.login, 'bravo');
    expect(orgsB.map((org) => org.login), ['bravo-org']);
    expect(oldOwnerProjects, isNull);
    expect(_projectTitles(newOwnerProjects), ['Bravo Personal Board']);
    expect(userProjectsB, isNull);
  });

  test('project issues paginate and bucket closed items locally', () async {
    final harness = await createTestContainer(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      graphqlTransportLink: _PagedProjectItemsLink(),
    );
    addTearDown(harness.container.dispose);

    await harness.container.read(sessionProvider.future);
    await harness.container
        .read(projectListProvider.notifier)
        .add(
          const Project(
            id: 'project-1',
            name: 'Inbox',
            ownerLogin: 'alpha',
            issueQuery: 'assignee:@me,octocat',
            dueDateFieldId: 'due-date',
            priorityFieldId: 'priority',
            priorityOptionMap: {'prio-high': TodoPriority.high},
          ),
        );

    final sub = harness.container.listen(
      projectIssuesProvider('project-1'),
      (_, _) {},
    );
    addTearDown(sub.close);
    final feed = await harness.container.read(
      projectIssuesProvider('project-1').future,
    );

    expect(feed.open.map((issue) => issue.title), [
      'Open early',
      'Open later',
      'Open no due date',
    ]);
    expect(feed.closed.map((issue) => issue.title), ['Closed recently']);
    expect(
      feed.open.firstWhere((issue) => issue.title == 'Open early').priority,
      TodoPriority.high,
    );
    expect(
      feed.open.firstWhere((issue) => issue.title == 'Open early').dueDate,
      '2026-04-22',
    );
    expect(feed.open.where((issue) => issue.title == 'Closed stale'), isEmpty);
  });

  test('issue comments provider maps comments oldest first', () async {
    final harness = await createTestContainer(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      graphqlTransportLink: _IssueCommentsLink(),
    );
    addTearDown(harness.container.dispose);

    await harness.container.read(sessionProvider.future);

    final sub = harness.container.listen(
      issueCommentsProvider('issue-1'),
      (_, _) {},
    );
    addTearDown(sub.close);
    final comments = await harness.container.read(
      issueCommentsProvider('issue-1').future,
    );

    expect(comments.map((comment) => comment.id), ['c-1', 'c-2', 'c-3']);
    expect(comments[0].authorLogin, 'alpha');
    expect(comments[1].authorLogin, isNull);
    expect(comments[2].body, 'Same timestamp, later id');
  });
}

const _accountA = FakeGithubGraphqlAccount(
  viewer: FakeGithubGraphqlViewer(
    id: 'user-a',
    login: 'alpha',
    name: 'Alpha User',
    avatarUrl: 'https://example.com/alpha.png',
  ),
  otherUsers: [
    FakeGithubGraphqlUser(
      login: 'GhDevCBue2',
      projects: [
        FakeGithubGraphqlProject(
          id: 'project-a-shared',
          title: 'Shared Personal Board',
        ),
      ],
    ),
  ],
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

class _PagedProjectItemsLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final operationName = _operationName(request);
    if (operationName != 'ProjectAssignedItemsPage') {
      throw StateError('Unexpected operation: $operationName');
    }

    final after = request.variables['after'] as String?;
    expect(request.variables['issueQuery'], 'assignee:@me,octocat');
    final payload = switch (after) {
      null => _projectItemsPageOne(),
      'cursor-1' => _projectItemsPageTwo(),
      _ => throw StateError('Unexpected cursor: $after'),
    };

    yield Response(data: payload, response: payload);
  }
}

class _IssueCommentsLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final operationName = _operationName(request);
    if (operationName != 'IssueComments') {
      throw StateError('Unexpected operation: $operationName');
    }

    yield Response(
      data: _issueCommentsPayload(),
      response: _issueCommentsPayload(),
    );
  }
}

Map<String, Object?> _projectItemsPageOne() {
  return {
    'node': {
      'items': {
        'nodes': [
          _projectIssue(
            itemId: 'item-open-later',
            issueId: 'issue-open-later',
            number: 11,
            title: 'Open later',
            updatedAt: '2026-04-20T10:00:00Z',
            state: 'OPEN',
            dueDate: '2026-04-23',
          ),
          _projectIssue(
            itemId: 'item-closed-recently',
            issueId: 'issue-closed-recently',
            number: 12,
            title: 'Closed recently',
            updatedAt: _instantIso(const Duration(days: -1)),
            state: 'CLOSED',
            closedAt: _instantIso(const Duration(days: -1)),
          ),
          _projectIssue(
            itemId: 'item-closed-stale',
            issueId: 'issue-closed-stale',
            number: 13,
            title: 'Closed stale',
            updatedAt: _instantIso(const Duration(days: -10)),
            state: 'CLOSED',
            closedAt: _instantIso(const Duration(days: -10)),
          ),
          {
            'id': 'item-draft',
            'fieldValues': {
              'nodes': const <Object?>[],
              '__typename': 'ProjectV2ItemFieldValueConnection',
            },
            'content': {'__typename': 'DraftIssue'},
            '__typename': 'ProjectV2Item',
          },
        ],
        'pageInfo': {
          'hasNextPage': true,
          'endCursor': 'cursor-1',
          '__typename': 'PageInfo',
        },
        '__typename': 'ProjectV2ItemConnection',
      },
      '__typename': 'ProjectV2',
    },
    'rateLimit': _rateLimit(),
    '__typename': 'Query',
  };
}

Map<String, Object?> _projectItemsPageTwo() {
  return {
    'node': {
      'items': {
        'nodes': [
          _projectIssue(
            itemId: 'item-open-early',
            issueId: 'issue-open-early',
            number: 14,
            title: 'Open early',
            updatedAt: '2026-04-19T08:00:00Z',
            state: 'OPEN',
            dueDate: '2026-04-22',
            priorityOptionId: 'prio-high',
          ),
          _projectIssue(
            itemId: 'item-open-no-due',
            issueId: 'issue-open-no-due',
            number: 15,
            title: 'Open no due date',
            updatedAt: '2026-04-21T06:00:00Z',
            state: 'OPEN',
          ),
        ],
        'pageInfo': {
          'hasNextPage': false,
          'endCursor': null,
          '__typename': 'PageInfo',
        },
        '__typename': 'ProjectV2ItemConnection',
      },
      '__typename': 'ProjectV2',
    },
    'rateLimit': _rateLimit(),
    '__typename': 'Query',
  };
}

String _instantIso(Duration offset) {
  return DateTime.now().toUtc().add(offset).toIso8601String();
}

Map<String, Object?> _projectIssue({
  required String itemId,
  required String issueId,
  required int number,
  required String title,
  required String updatedAt,
  required String state,
  String? closedAt,
  String? dueDate,
  String? priorityOptionId,
}) {
  return {
    'id': itemId,
    'fieldValues': {
      'nodes': [
        if (dueDate != null)
          {
            '__typename': 'ProjectV2ItemFieldDateValue',
            'date': dueDate,
            'field': {
              'id': 'due-date',
              'name': 'Due date',
              '__typename': 'ProjectV2Field',
            },
          },
        if (priorityOptionId != null)
          {
            '__typename': 'ProjectV2ItemFieldSingleSelectValue',
            'optionId': priorityOptionId,
            'name': 'High',
            'field': {
              'id': 'priority',
              'name': 'Priority',
              '__typename': 'ProjectV2SingleSelectField',
            },
          },
      ],
      '__typename': 'ProjectV2ItemFieldValueConnection',
    },
    'content': {
      'id': issueId,
      'url': 'https://github.com/acme/repo/issues/$number',
      'number': number,
      'title': title,
      'body': 'Issue body for $title',
      'bodyHTML': '<p>Issue body for $title</p>',
      'createdAt': '2026-04-18T09:00:00Z',
      'updatedAt': updatedAt,
      'state': state,
      'closedAt': closedAt,
      'comments': {'totalCount': 0, '__typename': 'IssueCommentConnection'},
      '__typename': 'Issue',
    },
    '__typename': 'ProjectV2Item',
  };
}

Map<String, Object?> _issueCommentsPayload() {
  return {
    'node': {
      'id': 'issue-1',
      'comments': {
        'nodes': [
          _comment(
            id: 'c-3',
            authorLogin: 'bravo',
            body: 'Same timestamp, later id',
            createdAt: '2026-04-13T11:00:00Z',
          ),
          _comment(
            id: 'c-1',
            authorLogin: 'alpha',
            body: 'First comment',
            createdAt: '2026-04-13T10:00:00Z',
          ),
          _comment(
            id: 'c-2',
            authorLogin: null,
            body: 'Same timestamp, earlier id',
            createdAt: '2026-04-13T11:00:00Z',
          ),
        ],
        '__typename': 'IssueCommentConnection',
      },
      '__typename': 'Issue',
    },
    'rateLimit': _rateLimit(),
    '__typename': 'Query',
  };
}

Map<String, Object?> _comment({
  required String id,
  required String? authorLogin,
  required String body,
  required String createdAt,
}) {
  return {
    'id': id,
    'createdAt': createdAt,
    'author': authorLogin == null
        ? null
        : {'login': authorLogin, '__typename': 'User'},
    'body': body,
    'bodyHTML': '<p>$body</p>',
    '__typename': 'IssueComment',
  };
}

Map<String, Object?> _rateLimit() {
  return {
    'cost': 1,
    'limit': 5000,
    'remaining': 4999,
    'resetAt': '2026-04-21T08:00:00Z',
    '__typename': 'RateLimit',
  };
}

String _operationName(Request request) {
  final explicitName = request.operation.operationName;
  if (explicitName != null && explicitName.isNotEmpty) {
    return explicitName;
  }

  for (final definition in request.operation.document.definitions) {
    final dynamic operationDefinition = definition;
    final dynamic nameNode = operationDefinition.name;
    final name = nameNode?.value;
    if (name is String && name.isNotEmpty) return name;
    break;
  }

  return 'anonymous';
}
