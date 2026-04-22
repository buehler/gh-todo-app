import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/app_logger_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:graphql/client.dart';

import '../support/fakes.dart';

void main() {
  group('graphqlClientProvider logging', () {
    test('logs named queries executed through userInfoProvider', () async {
      final harness = await createTestContainer(
        tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
        graphqlTransportLink: _OperationLink(
          handler: (request) => Response(
            data: _responseFor(_operationName(request)),
            response: _responseFor(_operationName(request)),
          ),
        ),
      );
      addTearDown(harness.container.dispose);

      await harness.container.read(sessionProvider.future);
      final client = harness.container.read(graphqlClientProvider);
      final result = await client.query$UserInformation(
        Options$Query$UserInformation(fetchPolicy: FetchPolicy.networkOnly),
      );
      expect(result.hasException, isFalse);

      final logLines = await _readLogsUntil(
        harness.logStore,
        containsText: '[graphql] query result: UserInformation | rateLimit',
      );
      expect(
        logLines.where(
          (line) => line.contains('[graphql] query: UserInformation'),
        ),
        hasLength(1),
      );
      expect(
        logLines.where(
          (line) => line.contains(
            '[graphql] query result: UserInformation | rateLimit cost=1 limit=5000 remaining=4999 resetAt=2026-04-21T08:00:00Z',
          ),
        ),
        hasLength(1),
      );
      expect(logLines.join('\n'), isNot(contains('ghp_seed')));
    });

    test('logs named mutations executed through the production client', () async {
      final harness = await createTestContainer(
        tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
        graphqlTransportLink: _OperationLink(
          handler: (request) =>
              Response(
                data: const {'__typename': 'Mutation'},
                response: const {'__typename': 'Mutation'},
              ).withContextEntry(
                const HttpLinkResponseContext(
                  statusCode: 200,
                  headers: {
                    'x-ratelimit-limit': '5000',
                    'x-ratelimit-remaining': '4994',
                    'x-ratelimit-reset': '1776758400',
                  },
                ),
              ),
        ),
      );
      addTearDown(harness.container.dispose);

      await harness.container.read(sessionProvider.future);
      final client = harness.container.read(graphqlClientProvider);
      await client.mutate(
        MutationOptions(document: gql('mutation PingMutation { __typename }')),
      );

      final logLines = await _readLogsUntil(
        harness.logStore,
        containsText: '[graphql] mutation: PingMutation',
      );
      expect(
        logLines.where(
          (line) => line.contains('[graphql] mutation: PingMutation'),
        ),
        hasLength(1),
      );
      expect(
        logLines.where(
          (line) => line.contains(
            '[graphql] mutation result: PingMutation | rateLimit cost=unavailable limit=5000 remaining=4994 resetAt=2026-04-21T08:00:00Z',
          ),
        ),
        hasLength(1),
      );
    });

    test('logs watched project queries once per execution cycle', () async {
      final harness = await createTestContainer(
        tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
        graphqlTransportLink: _OperationLink(
          handler: (request) => Response(
            data: _responseFor(_operationName(request)),
            response: _responseFor(_operationName(request)),
          ),
        ),
      );
      addTearDown(harness.container.dispose);

      await harness.container.read(sessionProvider.future);
      await harness.container
          .read(projectListProvider.notifier)
          .add(
            const Project(id: 'project-1', name: 'Inbox', ownerLogin: 'alpha'),
          );

      final sub = harness.container.listen(
        projectIssuesProvider('project-1'),
        (_, _) {},
      );
      addTearDown(sub.close);
      final feed = await harness.container.read(
        projectIssuesProvider('project-1').future,
      );

      expect(feed.open, hasLength(1));
      expect(feed.closed, isEmpty);

      final logLines = await _readLogsUntil(
        harness.logStore,
        containsText:
            '[graphql] query result: ProjectAssignedItemsPage | rateLimit',
      );
      expect(
        logLines.where(
          (line) => line.contains('[graphql] query: ProjectAssignedItemsPage'),
        ),
        hasLength(1),
      );
      expect(
        logLines.where(
          (line) => line.contains(
            '[graphql] query result: ProjectAssignedItemsPage | rateLimit cost=1 limit=5000 remaining=4999 resetAt=2026-04-21T08:00:00Z',
          ),
        ),
        hasLength(1),
      );
    });
  });
}

class _OperationLink extends Link {
  _OperationLink({required this.handler});

  final Response Function(Request request) handler;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    yield handler(request);
  }
}

Map<String, Object?> _responseFor(String operationName) {
  return switch (operationName) {
    'UserInformation' => {
      'viewer': {
        'id': 'user-1',
        'avatarUrl': 'https://example.com/me.png',
        'name': 'Alpha User',
        'login': 'alpha',
        '__typename': 'User',
      },
      'rateLimit': _rateLimit(),
      '__typename': 'Query',
    },
    'ProjectAssignedItemsPage' => {
      'node': {
        'items': {
          'nodes': [_projectItem()],
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
    },
    _ => throw StateError('Unexpected operation: $operationName'),
  };
}

Map<String, Object?> _projectItem() {
  return {
    'id': 'item-1',
    'fieldValues': {
      'nodes': const <Object?>[],
      '__typename': 'ProjectV2ItemFieldValueConnection',
    },
    'content': {
      'id': 'issue-1',
      'number': 7,
      'title': 'Log GraphQL operations',
      'createdAt': '2026-04-18T09:00:00Z',
      'updatedAt': '2026-04-18T09:00:00Z',
      'state': 'OPEN',
      'closedAt': null,
      'comments': {'totalCount': 0, '__typename': 'IssueCommentConnection'},
      '__typename': 'Issue',
    },
    '__typename': 'ProjectV2Item',
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

Future<List<String>> _readLogsUntil(
  AppLogStore store, {
  required String containsText,
}) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final lines = await store.readLines();
    if (lines.any((line) => line.contains(containsText))) {
      return lines;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return store.readLines();
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
