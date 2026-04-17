import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/issue_detail.graphql.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/project_issues.graphql.dart';
import 'package:gh_todos/graphql/user_orgs.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:graphql/client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_providers.g.dart';

/// The result of the project feed query: two independently sorted lists.
/// Matches the GraphQL response shape (`open` + `recentlyClosed`).
typedef ProjectIssuesFeed = ({List<IssueData> open, List<IssueData> closed});

final userInfoProvider =
    StreamProvider.autoDispose<Query$UserInformation$viewer?>((ref) {
      final client = ref.watch(graphqlClientProvider);
      return _cacheThenNetworkStream(
        readCache: () => client.readQuery$UserInformation(),
        fetchNetwork: () => client.query$UserInformation(
          Options$Query$UserInformation(fetchPolicy: FetchPolicy.networkOnly),
        ),
        mapper: (data) => data?.viewer,
      );
    });

final userOrganizationsProvider =
    StreamProvider.autoDispose<
      List<Query$UserOrganizations$viewer$organizations$nodes>
    >((ref) {
      final client = ref.watch(graphqlClientProvider);
      return _cacheThenNetworkStream(
        readCache: () => client.readQuery$UserOrganizations(),
        fetchNetwork: () => client.query$UserOrganizations(
          Options$Query$UserOrganizations(fetchPolicy: FetchPolicy.networkOnly),
        ),
        mapper: (data) =>
            data?.viewer.organizations.nodes
                ?.whereType<Query$UserOrganizations$viewer$organizations$nodes>()
                .toList() ??
            [],
      );
    });

final ownerProjectsProvider = StreamProvider.autoDispose
    .family<Query$OwnerProjects$node?, String>((ref, ownerId) {
      final client = ref.watch(graphqlClientProvider);
      return _cacheThenNetworkStream(
        readCache: () => client.readQuery$OwnerProjects(
          variables: Variables$Query$OwnerProjects(ownerId: ownerId),
        ),
        fetchNetwork: () => client.query$OwnerProjects(
          Options$Query$OwnerProjects(
            variables: Variables$Query$OwnerProjects(ownerId: ownerId),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        ),
        mapper: (data) => data?.node,
      );
    });

/// Owns the open + recently-closed issue lists for a single GitHub Project.
///
/// [build] does the initial network fetch (with a TTL-backed keepAlive so
/// switching projects feels instant); the `apply*` methods let the mutation
/// layer patch the cached lists directly when an issue is closed, reopened,
/// or created, avoiding a full refetch on every action.
///
/// Pull-to-refresh still works via `ref.invalidate(projectIssuesProvider(id))`
/// — that disposes the notifier and re-runs [build].
@riverpod
class ProjectIssues extends _$ProjectIssues {
  @override
  Stream<ProjectIssuesFeed> build(String projectId) {
    final projects = ref.watch(projectListProvider);
    final Project? project = projects
        .where((p) => p.id == projectId)
        .cast<Project?>()
        .firstOrNull;

    final client = ref.watch(graphqlClientProvider);
    return _watchQueryStream(
      ref,
      client.watchQuery$ProjectAssignedIssues(
        WatchOptions$Query$ProjectAssignedIssues(
          variables: Variables$Query$ProjectAssignedIssues(projectId: projectId),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
          eagerlyFetchResults: true,
          fetchResults: true,
        ),
      ),
      (parsed) {
        final openNodes =
            (parsed?.open is Query$ProjectAssignedIssues$open$$ProjectV2)
            ? (parsed!.open as Query$ProjectAssignedIssues$open$$ProjectV2)
                  .items
                  .nodes
            : null;
        final closedNodes =
            (parsed?.recentlyClosed
                is Query$ProjectAssignedIssues$recentlyClosed$$ProjectV2)
            ? (parsed!.recentlyClosed
                      as Query$ProjectAssignedIssues$recentlyClosed$$ProjectV2)
                  .items
                  .nodes
            : null;

        final open = _issuesFromNodes(
          openNodes,
          project: project,
          projectId: projectId,
          closed: false,
        )..sort(_compareOpenIssues);
        final closed = _issuesFromNodes(
          closedNodes,
          project: project,
          projectId: projectId,
          closed: true,
        )..sort(_compareClosedIssues);

        return (open: open, closed: closed);
      },
    );
  }

  /// Moves [issueId] from the open list to the closed list, stamping it with
  /// the [closedAt] / [updatedAt] returned by GitHub. No-op when the current
  /// state isn't `AsyncData` (still loading or errored) or when the issue
  /// isn't present — the next natural refetch will reconcile.
  void applyClose(
    String issueId, {
    required String? closedAt,
    required String updatedAt,
  }) {
    final feed = state.asData?.value;
    if (feed == null) return;

    final idx = feed.open.indexWhere((i) => i.id == issueId);
    if (idx == -1) return;

    final moved = feed.open[idx].copyWith(
      closed: true,
      closedAt: closedAt,
      updatedAt: updatedAt,
    );
    final nextOpen = [...feed.open]..removeAt(idx);
    final nextClosed = [...feed.closed, moved]..sort(_compareClosedIssues);
    state = AsyncData((open: nextOpen, closed: nextClosed));
  }

  /// Moves [issueId] from the closed list back to the open list, clearing
  /// `closedAt` and stamping the fresh [updatedAt]. No-op in the same
  /// conditions as [applyClose].
  void applyReopen(String issueId, {required String updatedAt}) {
    final feed = state.asData?.value;
    if (feed == null) return;

    final idx = feed.closed.indexWhere((i) => i.id == issueId);
    if (idx == -1) return;

    final moved = feed.closed[idx].copyWith(
      closed: false,
      closedAt: null,
      updatedAt: updatedAt,
    );
    final nextClosed = [...feed.closed]..removeAt(idx);
    final nextOpen = [...feed.open, moved]..sort(_compareOpenIssues);
    state = AsyncData((open: nextOpen, closed: nextClosed));
  }

  /// Inserts a freshly created [issue] into the open list so the composer's
  /// result appears immediately. If the id is already present anywhere in the
  /// feed (e.g. a refetch raced us), the call is ignored to avoid duplicates.
  void applyCreate(IssueData issue) {
    final feed = state.asData?.value;
    if (feed == null) return;
    final exists =
        feed.open.any((i) => i.id == issue.id) ||
        feed.closed.any((i) => i.id == issue.id);
    if (exists) return;

    final nextOpen = [...feed.open, issue]..sort(_compareOpenIssues);
    state = AsyncData((open: nextOpen, closed: feed.closed));
  }
}

/// Maps a list of project-item fragment nodes into concrete [IssueData].
/// Skips non-Issue contents (pull requests, drafts, etc.) and null entries.
List<IssueData> _issuesFromNodes(
  Iterable<Fragment$ProjectItemFields?>? nodes, {
  required Project? project,
  required String projectId,
  required bool closed,
}) {
  if (nodes == null) return <IssueData>[];
  final out = <IssueData>[];
  for (final item in nodes) {
    final issue = _issueFromItem(
      item,
      project: project,
      projectId: projectId,
      closed: closed,
    );
    if (issue != null) out.add(issue);
  }
  return out;
}

IssueData? _issueFromItem(
  Fragment$ProjectItemFields? item, {
  required Project? project,
  required String projectId,
  required bool closed,
}) {
  final content = item?.content;
  if (content is! Fragment$ProjectItemFields$content$$Issue) return null;

  final (priority, dueDate) = _resolveMappedFields(
    fieldValues: item?.fieldValues.nodes,
    project: project,
  );

  return IssueData(
    id: content.id,
    number: content.number,
    title: content.title,
    commentCount: content.comments.totalCount,
    createdAt: content.createdAt,
    updatedAt: content.updatedAt,
    closed: closed,
    closedAt: content.closedAt,
    priority: priority,
    dueDate: dueDate,
    projectId: projectId,
    projectItemId: item?.id,
  );
}

/// Walks the GitHub Project item's field values and pulls out the ones that
/// match the local mappings on [project]. Returns `(null, null)` when the
/// project has no mappings or no matching values are present.
(TodoPriority?, String?) _resolveMappedFields({
  required Iterable<Fragment$ProjectItemFields$fieldValues$nodes?>? fieldValues,
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
            is Fragment$ProjectItemFields$fieldValues$nodes$$ProjectV2ItemFieldSingleSelectValue) {
      final field = value.field;
      if (field
              is Fragment$ProjectItemFields$fieldValues$nodes$$ProjectV2ItemFieldSingleSelectValue$field$$ProjectV2SingleSelectField &&
          field.id == priorityFieldId) {
        final optionId = value.optionId;
        if (optionId != null) {
          priority = project.priorityOptionMap[optionId];
        }
      }
    } else if (dueDateFieldId != null &&
        value
            is Fragment$ProjectItemFields$fieldValues$nodes$$ProjectV2ItemFieldDateValue) {
      final field = value.field;
      if (field
              is Fragment$ProjectItemFields$fieldValues$nodes$$ProjectV2ItemFieldDateValue$field$$ProjectV2Field &&
          field.id == dueDateFieldId) {
        dueDate = value.date;
      }
    }
  }

  return (priority, dueDate);
}

/// Orders open issues by nearest due date first (nulls last), then by most
/// recently updated. ISO-8601 strings sort lexicographically, so no date
/// parsing is needed here.
int _compareOpenIssues(IssueData a, IssueData b) {
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

/// Orders closed issues by most recently closed first. Defensively falls back
/// to `updatedAt` when `closedAt` is unexpectedly null (shouldn't happen for
/// issues returned under `is:closed`, but the codegen types allow it).
int _compareClosedIssues(IssueData a, IssueData b) {
  final aClosed = a.closedAt ?? a.updatedAt;
  final bClosed = b.closedAt ?? b.updatedAt;
  return bClosed.compareTo(aClosed);
}

/// Fetches the description + comment thread for a single issue by its node id.
/// Kept separate from the project feed so the feed query doesn't over-fetch
/// comment bodies for issues the user never opens. Comments are returned in
/// chronological order (oldest first) — the conversation reads top-to-bottom
/// like a transcript, with the newest reply anchored at the bottom.
final issueDetailsProvider = StreamProvider.autoDispose
    .family<IssueDetails, String>((ref, issueId) {
      final client = ref.watch(graphqlClientProvider);
      return _watchQueryStream(
        ref,
        client.watchQuery$IssueDetail(
          WatchOptions$Query$IssueDetail(
          variables: Variables$Query$IssueDetail(id: issueId),
            fetchPolicy: FetchPolicy.cacheAndNetwork,
            eagerlyFetchResults: true,
            fetchResults: true,
          ),
        ),
        (parsed) {
          final node = parsed?.node;
          if (node is! Query$IssueDetail$node$$Issue) {
            return const IssueDetails(description: null, url: null, comments: []);
          }

          final commentNodes = node.comments.nodes ?? const [];
          final comments = <IssueComment>[];
          for (final c in commentNodes) {
            if (c == null) continue;
            comments.add(
              IssueComment(
                id: c.id,
                authorLogin: c.author?.login,
                body: c.bodyText,
                createdAt: c.createdAt,
              ),
            );
          }

          comments.sort((a, b) {
            final cmp = a.createdAt.compareTo(b.createdAt);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });

          final description = node.bodyText.trim();
          return IssueDetails(
            description: description.isEmpty ? null : description,
            url: node.url,
            comments: comments,
          );
        },
      );
    });

Stream<T> _watchQueryStream<TParsed, T>(
  Ref ref,
  ObservableQuery<TParsed> observable,
  T Function(TParsed? data) mapper,
) async* {
  ref.onDispose(observable.close);

  await for (final result in observable.stream) {
    final parsed = result.parsedData;
    if (parsed != null) {
      yield mapper(parsed);
      continue;
    }

    if (!result.isLoading && result.hasException) {
      throw result.exception!;
    }
  }
}

Stream<T> _cacheThenNetworkStream<TParsed, T>({
  required TParsed? Function() readCache,
  required Future<QueryResult<TParsed>> Function() fetchNetwork,
  required T Function(TParsed? data) mapper,
}) async* {
  var yieldedCachedValue = false;

  final cached = readCache();
  if (cached != null) {
    yieldedCachedValue = true;
    yield mapper(cached);
  }

  final result = await fetchNetwork();
  final parsed = result.parsedData;
  if (parsed != null) {
    yield mapper(parsed);
    return;
  }

  if (result.hasException && !yieldedCachedValue) {
    throw result.exception!;
  }
}
