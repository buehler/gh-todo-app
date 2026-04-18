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
        containsText: '[graphql] query: UserInformation',
      );
      expect(
        logLines.where(
          (line) => line.contains('[graphql] query: UserInformation'),
        ),
        hasLength(1),
      );
      expect(logLines.join('\n'), isNot(contains('ghp_seed')));
    });

    test(
      'logs named mutations executed through the production client',
      () async {
        final harness = await createTestContainer(
          tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
          graphqlTransportLink: _OperationLink(
            handler: (request) => const Response(
              data: {'__typename': 'Mutation'},
              response: {'__typename': 'Mutation'},
            ),
          ),
        );
        addTearDown(harness.container.dispose);

        await harness.container.read(sessionProvider.future);
        final client = harness.container.read(graphqlClientProvider);
        await client.mutate(
          MutationOptions(
            document: gql('mutation PingMutation { __typename }'),
          ),
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
      },
    );

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
        containsText: '[graphql] query: ProjectAssignedIssues',
      );
      expect(
        logLines.where(
          (line) => line.contains('[graphql] query: ProjectAssignedIssues'),
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
      '__typename': 'Query',
    },
    'ProjectAssignedIssues' => {
      'open': {
        'items': {
          'nodes': [_projectItem()],
          '__typename': 'ProjectV2ItemConnection',
        },
        '__typename': 'ProjectV2',
      },
      'recentlyClosed': {
        'items': {
          'nodes': const <Object?>[],
          '__typename': 'ProjectV2ItemConnection',
        },
        '__typename': 'ProjectV2',
      },
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
      'closedAt': null,
      'comments': {'totalCount': 0, '__typename': 'IssueCommentConnection'},
      '__typename': 'Issue',
    },
    '__typename': 'ProjectV2Item',
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
