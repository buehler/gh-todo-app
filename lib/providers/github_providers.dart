import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/project_issues.graphql.dart';
import 'package:gh_todos/graphql/user_orgs.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:graphql/client.dart';

/// Time after which cached project issues are considered stale and refetched
/// the next time the project is viewed.
const projectIssuesCacheTtl = Duration(hours: 1);

final userInfoProvider =
    FutureProvider.autoDispose<Query$UserInformation$viewer?>((ref) async {
  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$UserInformation();
  return result.parsedData?.viewer;
});

final userOrganizationsProvider = FutureProvider.autoDispose<
    List<Query$UserOrganizations$viewer$organizations$nodes>>((ref) async {
  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$UserOrganizations(
    Options$Query$UserOrganizations(
      fetchPolicy: FetchPolicy.networkOnly,
    ),
  );
  return result.parsedData?.viewer.organizations.nodes
          ?.whereType<Query$UserOrganizations$viewer$organizations$nodes>()
          .toList() ??
      [];
});

final ownerProjectsProvider = FutureProvider.autoDispose
    .family<Query$OwnerProjects$node?, String>((ref, ownerId) async {
  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$OwnerProjects(
    Options$Query$OwnerProjects(
      variables: Variables$Query$OwnerProjects(ownerId: ownerId),
      fetchPolicy: FetchPolicy.networkOnly,
    ),
  );
  return result.parsedData?.node;
});

final projectIssuesProvider = FutureProvider.autoDispose
    .family<List<IssueData>, String>((ref, projectId) async {
  // Keep this provider's result alive in Riverpod's cache for [projectIssuesCacheTtl]
  // even when no widget is watching it. This makes switching between projects
  // instant (cached data is returned immediately). After the TTL expires, the
  // provider auto-disposes so the next watch triggers a fresh fetch.
  // Pull-to-refresh bypasses this by calling ref.invalidate(provider).
  final link = ref.keepAlive();
  final timer = Timer(projectIssuesCacheTtl, link.close);
  ref.onDispose(timer.cancel);

  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$ProjectAssignedIssues(
    Options$Query$ProjectAssignedIssues(
      variables: Variables$Query$ProjectAssignedIssues(projectId: projectId),
      fetchPolicy: FetchPolicy.networkOnly,
    ),
  );

  final node = result.parsedData?.node;
  if (node is! Query$ProjectAssignedIssues$node$$ProjectV2) return [];

  final items = node.items.nodes ?? [];
  final issues = <IssueData>[];

  for (final item in items) {
    final content = item?.content;
    if (content
        is! Query$ProjectAssignedIssues$node$$ProjectV2$items$nodes$content$$Issue) {
      continue;
    }

    issues.add(IssueData(
      id: content.id,
      number: content.number,
      title: content.title,
      commentCount: content.comments.totalCount,
      createdAt: content.createdAt,
    ));
  }

  issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return issues;
});
