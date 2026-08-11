import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_details.freezed.dart';

/// A single GitHub issue comment, flattened for rendering on the detail page.
@freezed
abstract class IssueComment with _$IssueComment {
  const factory IssueComment({
    required String id,
    required String? authorLogin,
    required String body,
    required String bodyHtml,
    required String createdAt,
    @Default(false) bool isMinimized,
    String? minimizedReason,
    @Default(false) bool viewerCanDelete,
    @Default(false) bool viewerCanMinimize,
    @Default(false) bool viewerCanUnminimize,
    @Default(false) bool viewerCanUpdate,
  }) = _IssueComment;
}

/// The issue detail fields carried by the project issue snapshot.
@freezed
abstract class IssueDetails with _$IssueDetails {
  const factory IssueDetails({
    required String? body,
    required String? bodyHtml,

    /// Canonical HTML URL of the issue on github.com. Null if the node
    /// resolves to something other than an Issue (shouldn't happen under
    /// normal flows).
    required String? url,
  }) = _IssueDetails;
}
