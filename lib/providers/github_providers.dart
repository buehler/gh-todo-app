import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/project_issues.graphql.dart';
import 'package:gh_todos/graphql/user_orgs.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
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

  // Resolve the project (for its optional priority/due-date mappings) from the
  // local project list. Missing here means the project was removed locally
  // after the UI requested its issues; fall back to no-mapping behaviour.
  final projects = ref.watch(projectListProvider);
  final Project? project = projects
      .where((p) => p.id == projectId)
      .cast<Project?>()
      .firstOrNull;

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

    final (priority, dueDate) = _resolveMappedFields(
      fieldValues: item?.fieldValues.nodes,
      project: project,
    );

    issues.add(IssueData(
      id: content.id,
      number: content.number,
      title: content.title,
      commentCount: content.comments.totalCount,
      createdAt: content.createdAt,
      updatedAt: content.updatedAt,
      priority: priority,
      dueDate: dueDate,
    ));
  }

  issues.sort(_compareIssues);
  return issues;
});

/// Walks the GitHub Project item's field values and pulls out the ones that
/// match the local mappings on [project]. Returns `(null, null)` when the
/// project has no mappings or no matching values are present.
(TodoPriority?, String?) _resolveMappedFields({
  required Iterable<
          Query$ProjectAssignedIssues$node$$ProjectV2$items$nodes$fieldValues$nodes?>?
      fieldValues,
  required Project? project,
}) {
  if (project == null || fieldValues == null) return (null, null);

  final priorityFieldId = project.priorityFieldId;
  final dueDateFieldId = project.dueDateFieldId;
  if (priorityFieldId == null && dueDateFieldId == null) return (null, null);

  TodoPriority? priority;
  String? dueDate;

  for (final value in fieldValues) {
    if (value == null) continue;

    if (priorityFieldId != null &&
        value
            is Query$ProjectAssignedIssues$node$$ProjectV2$items$nodes$fieldValues$nodes$$ProjectV2ItemFieldSingleSelectValue) {
      final field = value.field;
      if (field
              is Query$ProjectAssignedIssues$node$$ProjectV2$items$nodes$fieldValues$nodes$$ProjectV2ItemFieldSingleSelectValue$field$$ProjectV2SingleSelectField &&
          field.id == priorityFieldId) {
        final optionId = value.optionId;
        if (optionId != null) {
          priority = project.priorityOptionMap[optionId];
        }
      }
    } else if (dueDateFieldId != null &&
        value
            is Query$ProjectAssignedIssues$node$$ProjectV2$items$nodes$fieldValues$nodes$$ProjectV2ItemFieldDateValue) {
      final field = value.field;
      if (field
              is Query$ProjectAssignedIssues$node$$ProjectV2$items$nodes$fieldValues$nodes$$ProjectV2ItemFieldDateValue$field$$ProjectV2Field &&
          field.id == dueDateFieldId) {
        dueDate = value.date;
      }
    }
  }

  return (priority, dueDate);
}

/// Orders issues by nearest due date first (nulls last), then by most recently
/// updated. ISO-8601 strings sort lexicographically, so no date parsing is
/// needed here.
int _compareIssues(IssueData a, IssueData b) {
  final aDue = a.dueDate;
  final bDue = b.dueDate;
  if (aDue != null || bDue != null) {
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    final cmp = aDue.compareTo(bDue);
    if (cmp != 0) return cmp;
  }
  return b.updatedAt.compareTo(a.updatedAt);
}
