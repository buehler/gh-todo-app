import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/issue_comments.graphql.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/project_issues.graphql.dart';
import 'package:gh_todos/graphql/schema.graphql.dart';
import 'package:gh_todos/graphql/user_orgs.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/models/issue_ordering.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/session_generation_provider.dart';
import 'package:graphql/client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_providers.g.dart';

/// The result of the project feed query: two independently sorted lists.
/// The buckets are derived locally from paginated project items.
typedef ProjectIssuesFeed = ({List<IssueData> open, List<IssueData> closed});

const Duration _recentlyClosedWindow = Duration(days: 3);

final userInfoProvider =
    FutureProvider.autoDispose<Query$UserInformation$viewer?>((ref) async {
      ref.watch(sessionGenerationProvider);
      final client = ref.watch(graphqlClientProvider);
      final result = await client.query$UserInformation(
        Options$Query$UserInformation(fetchPolicy: FetchPolicy.networkOnly),
      );
      final parsed = result.parsedData;
      if (parsed != null) {
        return parsed.viewer;
      }
      if (result.hasException) {
        throw result.exception!;
      }
      return null;
    });

final userOrganizationsProvider =
    FutureProvider.autoDispose<
      List<Query$UserOrganizations$viewer$organizations$nodes>
    >((ref) async {
      ref.watch(sessionGenerationProvider);
      final client = ref.watch(graphqlClientProvider);
      final result = await client.query$UserOrganizations(
        Options$Query$UserOrganizations(fetchPolicy: FetchPolicy.networkOnly),
      );
      final parsed = result.parsedData;
      if (parsed != null) {
        return parsed.viewer.organizations.nodes
                ?.whereType<
                  Query$UserOrganizations$viewer$organizations$nodes
                >()
                .toList() ??
            [];
      }
      if (result.hasException) {
        throw result.exception!;
      }
      return const [];
    });

final ownerProjectsProvider = FutureProvider.autoDispose
    .family<Query$OwnerProjects$node?, String>((ref, ownerId) async {
      ref.watch(sessionGenerationProvider);
      final client = ref.watch(graphqlClientProvider);
      final result = await client.query$OwnerProjects(
        Options$Query$OwnerProjects(
          variables: Variables$Query$OwnerProjects(ownerId: ownerId),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      final parsed = result.parsedData;
      if (parsed != null) {
        return parsed.node;
      }
      if (result.hasException) {
        throw result.exception!;
      }
      return null;
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
@Riverpod(keepAlive: true)
class ProjectIssues extends _$ProjectIssues {
  @override
  Stream<ProjectIssuesFeed> build(String projectId) {
    final projects = ref.watch(projectListProvider);
    final Project? project = projects
        .where((p) => p.id == projectId)
        .cast<Project?>()
        .firstOrNull;

    final client = ref.watch(graphqlClientProvider);
    return Stream.fromFuture(
      _loadProjectIssuesFeed(client, projectId: projectId, project: project),
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
    final nextOpen = [...feed.open, moved]..sort(compareOpenIssues);
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

    final nextOpen = [...feed.open, issue]..sort(compareOpenIssues);
    state = AsyncData((open: nextOpen, closed: feed.closed));
  }
}

Future<ProjectIssuesFeed> _loadProjectIssuesFeed(
  GraphQLClient client, {
  required String projectId,
  required Project? project,
}) async {
  final nowUtc = DateTime.now().toUtc();
  final nodes = await _fetchProjectItemNodes(client, projectId: projectId);
  final open = <IssueData>[];
  final closed = <IssueData>[];

  for (final item in nodes) {
    final issue = _issueFromItem(item, project: project, projectId: projectId);
    if (issue == null) continue;

    if (!issue.closed) {
      open.add(issue);
      continue;
    }

    if (_isRecentlyClosed(issue, nowUtc: nowUtc)) {
      closed.add(issue);
    }
  }

  open.sort(compareOpenIssues);
  closed.sort(_compareClosedIssues);
  return (open: open, closed: closed);
}

Future<List<Fragment$ProjectItemFields?>> _fetchProjectItemNodes(
  GraphQLClient client, {
  required String projectId,
}) async {
  final nodes = <Fragment$ProjectItemFields?>[];
  String? after;

  while (true) {
    final result = await client.query$ProjectAssignedItemsPage(
      Options$Query$ProjectAssignedItemsPage(
        variables: Variables$Query$ProjectAssignedItemsPage(
          projectId: projectId,
          after: after,
        ),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    final parsed = result.parsedData;
    if (parsed == null) {
      if (result.hasException) {
        throw result.exception!;
      }
      break;
    }

    final node = parsed.node;
    if (node is! Query$ProjectAssignedItemsPage$node$$ProjectV2) break;

    nodes.addAll(node.items.nodes ?? const []);
    final pageInfo = node.items.pageInfo;
    if (!pageInfo.hasNextPage) break;
    after = pageInfo.endCursor;
    if (after == null || after.isEmpty) break;
  }

  return nodes;
}

/// Maps a list of project-item fragment nodes into concrete [IssueData].
/// Skips non-Issue contents (pull requests, drafts, etc.) and null entries.
IssueData? _issueFromItem(
  Fragment$ProjectItemFields? item, {
  required Project? project,
  required String projectId,
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
    url: content.url,
    description: _nullableTrimmed(content.bodyText),
    commentCount: content.comments.totalCount,
    createdAt: content.createdAt,
    updatedAt: content.updatedAt,
    closed: content.state == Enum$IssueState.CLOSED,
    closedAt: content.closedAt,
    priority: priority,
    dueDate: dueDate,
    projectId: projectId,
    projectItemId: item?.id,
  );
}

bool _isRecentlyClosed(IssueData issue, {required DateTime nowUtc}) {
  final closedAt = issue.closedAt ?? issue.updatedAt;
  final closedInstant = DateTime.tryParse(closedAt)?.toUtc();
  if (closedInstant == null) return false;
  return !closedInstant.isBefore(nowUtc.subtract(_recentlyClosedWindow));
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

/// Orders closed issues by most recently closed first. Defensively falls back
/// to `updatedAt` when `closedAt` is unexpectedly null (shouldn't happen for
/// issues returned under `is:closed`, but the codegen types allow it).
int _compareClosedIssues(IssueData a, IssueData b) {
  final aClosed = a.closedAt ?? a.updatedAt;
  final bClosed = b.closedAt ?? b.updatedAt;
  return bClosed.compareTo(aClosed);
}

String? _nullableTrimmed(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final issueDetailsProvider = Provider.family<IssueDetails, IssueData>(
  (ref, issue) => IssueDetails(description: issue.description, url: issue.url),
);

/// Fetches the comment thread for a single issue by its node id.
///
/// Comments are returned in chronological order (oldest first), so the
/// conversation reads top-to-bottom like a transcript.
final issueCommentsProvider = StreamProvider.autoDispose
    .family<List<IssueComment>, String>((ref, issueId) {
      final client = ref.watch(graphqlClientProvider);
      return _watchQueryStream(
        ref,
        client.watchQuery$IssueComments(
          WatchOptions$Query$IssueComments(
            variables: Variables$Query$IssueComments(id: issueId),
            fetchPolicy: FetchPolicy.cacheAndNetwork,
            eagerlyFetchResults: true,
            fetchResults: true,
          ),
        ),
        (parsed) {
          final node = parsed?.node;
          if (node is! Query$IssueComments$node$$Issue) {
            return const <IssueComment>[];
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

          return comments;
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
