import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/add_comment.graphql.dart';
import 'package:gh_todos/graphql/add_project_item.graphql.dart';
import 'package:gh_todos/graphql/clear_project_item_field.graphql.dart';
import 'package:gh_todos/graphql/close_issue.graphql.dart';
import 'package:gh_todos/graphql/create_issue.graphql.dart';
import 'package:gh_todos/graphql/project_repository.graphql.dart';
import 'package:gh_todos/graphql/reopen_issue.graphql.dart';
import 'package:gh_todos/graphql/schema.graphql.dart';
import 'package:gh_todos/graphql/update_issue.graphql.dart';
import 'package:gh_todos/graphql/update_issue_comment.graphql.dart';
import 'package:gh_todos/graphql/update_project_item_field.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:graphql/client.dart';

/// Narrow seam for all GitHub mutations fired from the issue detail page.
///
/// The interface exists so widget tests can override the provider with a
/// fake recorder — stubbing the underlying GraphQL client would require
/// fabricating full typed `QueryResult<Mutation$...>` payloads for every
/// mutation, which is painful. Callers always go through the provider.
abstract class IssueMutations {
  Future<void> postComment({required String issueId, required String body});

  Future<void> updateComment({
    required String issueId,
    required String commentId,
    required String body,
  });

  Future<CloseIssueResult> closeIssue({
    required String projectId,
    required String issueId,
  });

  Future<ReopenIssueResult> reopenIssue({
    required String projectId,
    required String issueId,
  });

  Future<UpdateIssueCoreResult> updateIssueCore({
    required String projectId,
    required String issueId,
    String? title,
    String? body,
  });

  Future<void> setProjectItemDate({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String isoDate,
  });

  Future<void> setProjectItemSingleSelect({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String optionId,
  });

  Future<void> clearProjectItemField({
    required String projectId,
    required String itemId,
    required String fieldId,
  });

  /// Creates a new GitHub Issue in the selected project's first linked
  /// repository and attaches it as a ProjectV2 item on [projectId].
  ///
  /// Throws [NoLinkedRepositoryException] when the project has no linked
  /// repositories — issues can only be created against a repository, so the
  /// UI surfaces this as "link a repo in GitHub to enable quick-add".
  Future<IssueData> createIssueInProject({
    required String projectId,
    required String title,
    String? body,
  });
}

/// Thrown by [IssueMutations.createIssueInProject] when the selected project
/// has no linked repositories. The composer catches this to show a targeted
/// error instead of a generic "failed to create issue" message.
class NoLinkedRepositoryException implements Exception {
  final String projectId;

  const NoLinkedRepositoryException(this.projectId);

  @override
  String toString() =>
      'NoLinkedRepositoryException: project $projectId has no linked repository';
}

class CloseIssueResult {
  final bool closed;
  final String? closedAt;
  final String updatedAt;

  const CloseIssueResult({
    required this.closed,
    required this.closedAt,
    required this.updatedAt,
  });
}

class ReopenIssueResult {
  final bool closed;
  final String updatedAt;

  const ReopenIssueResult({required this.closed, required this.updatedAt});
}

class UpdateIssueCoreResult {
  final String title;
  final String bodyText;
  final String updatedAt;

  const UpdateIssueCoreResult({
    required this.title,
    required this.bodyText,
    required this.updatedAt,
  });
}

final issueMutationsProvider = Provider<IssueMutations>(
  (ref) => _RealIssueMutations(ref),
);

class _RealIssueMutations implements IssueMutations {
  final Ref _ref;

  _RealIssueMutations(this._ref);

  GraphQLClient get _client => _ref.read(graphqlClientProvider);

  /// Throws the GraphQL exception wrapped in [result] when present so the
  /// caller can `try/catch` and surface a SnackBar. Also guards against the
  /// `parsedData == null` case where the server accepted the request but
  /// didn't return anything useful.
  T _unwrap<T>(QueryResult<T> result) {
    if (result.hasException) throw result.exception!;
    final data = result.parsedData;
    if (data == null) {
      throw Exception('Mutation returned no data');
    }
    return data;
  }

  @override
  Future<void> postComment({
    required String issueId,
    required String body,
  }) async {
    final result = await _client.mutate$AddIssueComment(
      Options$Mutation$AddIssueComment(
        variables: Variables$Mutation$AddIssueComment(
          issueId: issueId,
          body: body,
        ),
      ),
    );
    _unwrap(result);
    _ref.invalidate(issueDetailsProvider(issueId));
  }

  @override
  Future<void> updateComment({
    required String issueId,
    required String commentId,
    required String body,
  }) async {
    final result = await _client.mutate$UpdateIssueComment(
      Options$Mutation$UpdateIssueComment(
        variables: Variables$Mutation$UpdateIssueComment(
          commentId: commentId,
          body: body,
        ),
      ),
    );
    _unwrap(result);
    _ref.invalidate(issueDetailsProvider(issueId));
  }

  @override
  Future<CloseIssueResult> closeIssue({
    required String projectId,
    required String issueId,
  }) async {
    final result = await _client.mutate$CloseIssue(
      Options$Mutation$CloseIssue(
        variables: Variables$Mutation$CloseIssue(issueId: issueId),
      ),
    );
    final data = _unwrap(result);
    final issue = data.closeIssue?.issue;
    if (issue == null) {
      // Response didn't carry the refreshed issue — fall back to a full
      // refetch so the feed doesn't desync.
      _ref.invalidate(projectIssuesProvider(projectId));
      return const CloseIssueResult(
        closed: true,
        closedAt: null,
        updatedAt: '',
      );
    }
    // Patch the cached feed directly so the card moves to "Recently closed"
    // without waiting for a refetch.
    _ref
        .read(projectIssuesProvider(projectId).notifier)
        .applyClose(
          issueId,
          closedAt: issue.closedAt,
          updatedAt: issue.updatedAt,
        );
    return CloseIssueResult(
      closed: issue.state == Enum$IssueState.CLOSED,
      closedAt: issue.closedAt,
      updatedAt: issue.updatedAt,
    );
  }

  @override
  Future<ReopenIssueResult> reopenIssue({
    required String projectId,
    required String issueId,
  }) async {
    final result = await _client.mutate$ReopenIssue(
      Options$Mutation$ReopenIssue(
        variables: Variables$Mutation$ReopenIssue(issueId: issueId),
      ),
    );
    final data = _unwrap(result);
    final issue = data.reopenIssue?.issue;
    if (issue == null) {
      _ref.invalidate(projectIssuesProvider(projectId));
      return const ReopenIssueResult(closed: false, updatedAt: '');
    }
    _ref
        .read(projectIssuesProvider(projectId).notifier)
        .applyReopen(issueId, updatedAt: issue.updatedAt);
    return ReopenIssueResult(
      closed: issue.state == Enum$IssueState.CLOSED,
      updatedAt: issue.updatedAt,
    );
  }

  @override
  Future<UpdateIssueCoreResult> updateIssueCore({
    required String projectId,
    required String issueId,
    String? title,
    String? body,
  }) async {
    final result = await _client.mutate$UpdateIssueCore(
      Options$Mutation$UpdateIssueCore(
        variables: Variables$Mutation$UpdateIssueCore(
          issueId: issueId,
          title: title,
          body: body,
        ),
      ),
    );
    final data = _unwrap(result);
    final issue = data.updateIssue?.issue;
    _ref.invalidate(issueDetailsProvider(issueId));
    _ref.invalidate(projectIssuesProvider(projectId));
    if (issue == null) {
      return UpdateIssueCoreResult(
        title: title ?? '',
        bodyText: body ?? '',
        updatedAt: '',
      );
    }
    return UpdateIssueCoreResult(
      title: issue.title,
      bodyText: issue.bodyText,
      updatedAt: issue.updatedAt,
    );
  }

  @override
  Future<void> setProjectItemDate({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String isoDate,
  }) async {
    final result = await _client.mutate$UpdateProjectItemField(
      Options$Mutation$UpdateProjectItemField(
        variables: Variables$Mutation$UpdateProjectItemField(
          projectId: projectId,
          itemId: itemId,
          fieldId: fieldId,
          value: Input$ProjectV2FieldValue(date: isoDate),
        ),
      ),
    );
    _unwrap(result);
    _ref.invalidate(projectIssuesProvider(projectId));
  }

  @override
  Future<void> setProjectItemSingleSelect({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String optionId,
  }) async {
    final result = await _client.mutate$UpdateProjectItemField(
      Options$Mutation$UpdateProjectItemField(
        variables: Variables$Mutation$UpdateProjectItemField(
          projectId: projectId,
          itemId: itemId,
          fieldId: fieldId,
          value: Input$ProjectV2FieldValue(singleSelectOptionId: optionId),
        ),
      ),
    );
    _unwrap(result);
    _ref.invalidate(projectIssuesProvider(projectId));
  }

  @override
  Future<void> clearProjectItemField({
    required String projectId,
    required String itemId,
    required String fieldId,
  }) async {
    final result = await _client.mutate$ClearProjectItemField(
      Options$Mutation$ClearProjectItemField(
        variables: Variables$Mutation$ClearProjectItemField(
          projectId: projectId,
          itemId: itemId,
          fieldId: fieldId,
        ),
      ),
    );
    _unwrap(result);
    _ref.invalidate(projectIssuesProvider(projectId));
  }

  @override
  Future<IssueData> createIssueInProject({
    required String projectId,
    required String title,
    String? body,
  }) async {
    // Step 1: resolve the target repository. Projects V2 don't have a
    // "default repo" concept, so we pick the first linked repository
    // (alphabetical by name) and fail loudly when there's none.
    final repoResult = await _client.query$ProjectFirstRepository(
      Options$Query$ProjectFirstRepository(
        variables: Variables$Query$ProjectFirstRepository(projectId: projectId),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    final repoData = _unwrap(repoResult);
    final node = repoData.node;
    final repositoryId =
        (node is Query$ProjectFirstRepository$node$$ProjectV2)
            ? node.repositories.nodes?.firstWhere(
                  (n) => n != null,
                  orElse: () => null,
                )?.id
            : null;
    if (repositoryId == null) {
      throw NoLinkedRepositoryException(projectId);
    }

    // Step 2: create the issue in the repository, assigned to the current
    // viewer. The root feed's query filters by `assignee:@me`, so without
    // self-assigning the new issue would be invisible in the todo list.
    final viewer = await _ref.read(userInfoProvider.future);
    final viewerId = viewer?.id;
    final createResult = await _client.mutate$CreateIssue(
      Options$Mutation$CreateIssue(
        variables: Variables$Mutation$CreateIssue(
          repositoryId: repositoryId,
          title: title,
          body: body,
          assigneeIds: viewerId != null ? [viewerId] : null,
        ),
      ),
    );
    final createData = _unwrap(createResult);
    final issue = createData.createIssue?.issue;
    if (issue == null) {
      throw Exception('createIssue returned no issue payload');
    }

    // Step 3: attach the new issue to the project.
    final addResult = await _client.mutate$AddProjectItem(
      Options$Mutation$AddProjectItem(
        variables: Variables$Mutation$AddProjectItem(
          projectId: projectId,
          contentId: issue.id,
        ),
      ),
    );
    final addData = _unwrap(addResult);
    final projectItemId = addData.addProjectV2ItemById?.item?.id;

    final newIssue = IssueData(
      id: issue.id,
      number: issue.number,
      title: issue.title,
      commentCount: 0,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
      closed: false,
      projectId: projectId,
      projectItemId: projectItemId,
    );

    // Splice the new issue into the cached feed so it appears instantly.
    _ref
        .read(projectIssuesProvider(projectId).notifier)
        .applyCreate(newIssue);

    return newIssue;
  }
}
