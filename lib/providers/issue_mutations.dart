import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/add_comment.graphql.dart';
import 'package:gh_todos/graphql/clear_project_item_field.graphql.dart';
import 'package:gh_todos/graphql/close_issue.graphql.dart';
import 'package:gh_todos/graphql/reopen_issue.graphql.dart';
import 'package:gh_todos/graphql/schema.graphql.dart';
import 'package:gh_todos/graphql/update_issue.graphql.dart';
import 'package:gh_todos/graphql/update_issue_comment.graphql.dart';
import 'package:gh_todos/graphql/update_project_item_field.graphql.dart';
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
    _ref.invalidate(projectIssuesProvider(projectId));
    if (issue == null) {
      return const CloseIssueResult(
        closed: true,
        closedAt: null,
        updatedAt: '',
      );
    }
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
    _ref.invalidate(projectIssuesProvider(projectId));
    if (issue == null) {
      return const ReopenIssueResult(closed: false, updatedAt: '');
    }
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
}
