import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/providers/issue_mutations.dart';

/// Recorder + stub for [IssueMutations], used by widget tests that don't want
/// to fabricate full typed `QueryResult<Mutation$...>` payloads.
///
/// Every invocation appends a typed struct to [calls] so tests can assert on
/// both the mutation kind and its arguments. Flip [throwNext] to force the
/// next call to throw; useful for the SnackBar error-path tests.
class FakeIssueMutations implements IssueMutations {
  final List<MutationCall> calls = <MutationCall>[];

  bool throwNext = false;

  /// Canned payloads returned by [closeIssue] / [reopenIssue] /
  /// [updateIssueCore]. Tests may swap these out to exercise specific
  /// post-mutation state (e.g. verify that `closedAt` propagates into the
  /// local `IssueData`).
  CloseIssueResult closeResult = const CloseIssueResult(
    closed: true,
    closedAt: '2026-04-15T12:00:00Z',
    updatedAt: '2026-04-15T12:00:00Z',
  );

  ReopenIssueResult reopenResult = const ReopenIssueResult(
    closed: false,
    updatedAt: '2026-04-15T12:00:00Z',
  );

  UpdateIssueCoreResult updateIssueResult = const UpdateIssueCoreResult(
    title: '',
    bodyText: '',
    updatedAt: '2026-04-15T12:00:00Z',
  );

  void _maybeThrow() {
    if (!throwNext) return;
    throwNext = false;
    throw Exception('fake failure');
  }

  @override
  Future<void> postComment({
    required String issueId,
    required String body,
  }) async {
    calls.add(PostCommentCall(issueId: issueId, body: body));
    _maybeThrow();
  }

  @override
  Future<void> updateComment({
    required String issueId,
    required String commentId,
    required String body,
  }) async {
    calls.add(
      UpdateCommentCall(issueId: issueId, commentId: commentId, body: body),
    );
    _maybeThrow();
  }

  @override
  Future<CloseIssueResult> closeIssue({
    required String projectId,
    required String issueId,
  }) async {
    calls.add(CloseIssueCall(projectId: projectId, issueId: issueId));
    _maybeThrow();
    return closeResult;
  }

  @override
  Future<ReopenIssueResult> reopenIssue({
    required String projectId,
    required String issueId,
  }) async {
    calls.add(ReopenIssueCall(projectId: projectId, issueId: issueId));
    _maybeThrow();
    return reopenResult;
  }

  @override
  Future<UpdateIssueCoreResult> updateIssueCore({
    required String projectId,
    required String issueId,
    String? title,
    String? body,
  }) async {
    calls.add(
      UpdateIssueCoreCall(
        projectId: projectId,
        issueId: issueId,
        title: title,
        body: body,
      ),
    );
    _maybeThrow();
    return UpdateIssueCoreResult(
      title: title ?? updateIssueResult.title,
      bodyText: body ?? updateIssueResult.bodyText,
      updatedAt: updateIssueResult.updatedAt,
    );
  }

  @override
  Future<void> setProjectItemDate({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String isoDate,
  }) async {
    calls.add(
      SetProjectItemDateCall(
        projectId: projectId,
        itemId: itemId,
        fieldId: fieldId,
        isoDate: isoDate,
      ),
    );
    _maybeThrow();
  }

  @override
  Future<void> setProjectItemSingleSelect({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String optionId,
  }) async {
    calls.add(
      SetProjectItemSingleSelectCall(
        projectId: projectId,
        itemId: itemId,
        fieldId: fieldId,
        optionId: optionId,
      ),
    );
    _maybeThrow();
  }

  @override
  Future<void> clearProjectItemField({
    required String projectId,
    required String itemId,
    required String fieldId,
  }) async {
    calls.add(
      ClearProjectItemFieldCall(
        projectId: projectId,
        itemId: itemId,
        fieldId: fieldId,
      ),
    );
    _maybeThrow();
  }

  /// When true, [createIssueInProject] throws [NoLinkedRepositoryException]
  /// instead of returning a canned issue — used by tests exercising the
  /// "no linked repo" error path in the composer.
  bool throwNoLinkedRepo = false;

  /// Canned issue returned by [createIssueInProject] on success.
  IssueData createIssueResult = const IssueData(
    id: 'issue-new',
    number: 101,
    title: 'New todo',
    commentCount: 0,
    createdAt: '2026-04-15T12:00:00Z',
    updatedAt: '2026-04-15T12:00:00Z',
  );

  @override
  Future<IssueData> createIssueInProject({
    required String projectId,
    required String title,
    String? body,
  }) async {
    calls.add(
      CreateIssueInProjectCall(
        projectId: projectId,
        title: title,
        body: body,
      ),
    );
    if (throwNoLinkedRepo) {
      throwNoLinkedRepo = false;
      throw NoLinkedRepositoryException(projectId);
    }
    _maybeThrow();
    return createIssueResult;
  }
}

// --- Call types --------------------------------------------------------------

sealed class MutationCall {
  const MutationCall();
}

class PostCommentCall extends MutationCall {
  final String issueId;
  final String body;
  const PostCommentCall({required this.issueId, required this.body});
}

class UpdateCommentCall extends MutationCall {
  final String issueId;
  final String commentId;
  final String body;
  const UpdateCommentCall({
    required this.issueId,
    required this.commentId,
    required this.body,
  });
}

class CloseIssueCall extends MutationCall {
  final String projectId;
  final String issueId;
  const CloseIssueCall({required this.projectId, required this.issueId});
}

class ReopenIssueCall extends MutationCall {
  final String projectId;
  final String issueId;
  const ReopenIssueCall({required this.projectId, required this.issueId});
}

class UpdateIssueCoreCall extends MutationCall {
  final String projectId;
  final String issueId;
  final String? title;
  final String? body;
  const UpdateIssueCoreCall({
    required this.projectId,
    required this.issueId,
    required this.title,
    required this.body,
  });
}

class SetProjectItemDateCall extends MutationCall {
  final String projectId;
  final String itemId;
  final String fieldId;
  final String isoDate;
  const SetProjectItemDateCall({
    required this.projectId,
    required this.itemId,
    required this.fieldId,
    required this.isoDate,
  });
}

class SetProjectItemSingleSelectCall extends MutationCall {
  final String projectId;
  final String itemId;
  final String fieldId;
  final String optionId;
  const SetProjectItemSingleSelectCall({
    required this.projectId,
    required this.itemId,
    required this.fieldId,
    required this.optionId,
  });
}

class ClearProjectItemFieldCall extends MutationCall {
  final String projectId;
  final String itemId;
  final String fieldId;
  const ClearProjectItemFieldCall({
    required this.projectId,
    required this.itemId,
    required this.fieldId,
  });
}

class CreateIssueInProjectCall extends MutationCall {
  final String projectId;
  final String title;
  final String? body;
  const CreateIssueInProjectCall({
    required this.projectId,
    required this.title,
    required this.body,
  });
}
