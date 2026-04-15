import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_details.freezed.dart';

/// A single GitHub issue comment, flattened for rendering on the detail page.
@freezed
abstract class IssueComment with _$IssueComment {
  const factory IssueComment({
    required String id,
    required String? authorLogin,
    required String body,
    required String createdAt,
  }) = _IssueComment;
}

/// The deferred-loaded portion of an issue: its description, canonical URL,
/// and comment thread. Fetched by the detail page; kept separate from
/// [IssueData] so the feed query doesn't have to over-fetch.
@freezed
abstract class IssueDetails with _$IssueDetails {
  const factory IssueDetails({
    required String? description,

    /// Canonical HTML URL of the issue on github.com. Null if the node
    /// resolves to something other than an Issue (shouldn't happen under
    /// normal flows).
    required String? url,
    required List<IssueComment> comments,
  }) = _IssueDetails;
}
