import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gh_todos/models/priority.dart';

part 'issue_data.freezed.dart';
part 'issue_data.g.dart';

/// Snapshot of an issue as it's surfaced on the feed + detail page.
///
/// Carries both the issue node id ([id]) and the GitHub Projects V2
/// [projectItemId]; the latter is required when mutating project-scoped
/// fields (priority, due date) — those mutations target the item, not the
/// issue.
@freezed
abstract class IssueData with _$IssueData {
  const factory IssueData({
    required String id,
    required int number,
    required String title,
    String? url,
    String? description,
    required int commentCount,
    required String createdAt,
    required String updatedAt,

    /// `true` when the issue is currently closed according to GitHub issue
    /// state. Drives muted rendering and closed-list membership.
    @Default(false) bool closed,

    /// ISO-8601 timestamp of when the issue was closed. Non-null when
    /// [closed] is true (GitHub guarantees `closedAt` for closed issues).
    String? closedAt,

    /// Resolved local priority when the issue's GitHub Project item has a
    /// value for the mapped single-select field and the selected option is
    /// present in [Project.priorityOptionMap]. `null` otherwise.
    TodoPriority? priority,

    /// `YYYY-MM-DD` date string when the issue's GitHub Project item has a
    /// value for the mapped date field. `null` otherwise.
    String? dueDate,

    /// GitHub Projects V2 project id this issue was surfaced from. Null
    /// when the feed entry couldn't be traced back to a project (shouldn't
    /// happen in normal flows but tolerated for defensive construction —
    /// e.g. tests).
    String? projectId,

    /// GitHub Projects V2 **item** id — distinct from [id] (the issue node
    /// id). Required when mutating project-scoped fields.
    String? projectItemId,
  }) = _IssueData;

  factory IssueData.fromJson(Map<String, Object?> json) =>
      _$IssueDataFromJson(json);
}
