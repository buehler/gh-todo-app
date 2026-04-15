import 'package:gh_todos/models/priority.dart';
import 'package:json_annotation/json_annotation.dart';

part 'issue_data.g.dart';

@JsonSerializable()
class IssueData {
  final String id;
  final int number;
  final String title;
  final int commentCount;
  final String createdAt;
  final String updatedAt;

  /// `true` when the issue was sourced from the "recently closed" arm of the
  /// feed query (closed within the last few days). Drives muted rendering.
  @JsonKey(defaultValue: false)
  final bool closed;

  /// ISO-8601 timestamp of when the issue was closed. Non-null when [closed]
  /// is true (GitHub guarantees `closedAt` for closed issues).
  final String? closedAt;

  /// Resolved local priority when the issue's GitHub Project item has a value
  /// for the mapped single-select field and the selected option is present in
  /// [Project.priorityOptionMap]. `null` otherwise.
  final TodoPriority? priority;

  /// `YYYY-MM-DD` date string when the issue's GitHub Project item has a
  /// value for the mapped date field. `null` otherwise.
  final String? dueDate;

  /// GitHub Projects V2 project id this issue was surfaced from. Null when
  /// the feed entry couldn't be traced back to a project (shouldn't happen in
  /// normal flows but tolerated for defensive construction — e.g. tests).
  final String? projectId;

  /// GitHub Projects V2 **item** id — distinct from [id] (the issue node id).
  /// Required when mutating project-scoped fields (priority, due date); those
  /// mutations target the item, not the issue. Null when we couldn't resolve
  /// it (same caveat as [projectId]).
  final String? projectItemId;

  const IssueData({
    required this.id,
    required this.number,
    required this.title,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
    this.closed = false,
    this.closedAt,
    this.priority,
    this.dueDate,
    this.projectId,
    this.projectItemId,
  });

  factory IssueData.fromJson(Map<String, dynamic> json) =>
      _$IssueDataFromJson(json);

  Map<String, dynamic> toJson() => _$IssueDataToJson(this);

  /// Returns a copy of this issue with the given fields replaced.
  ///
  /// Uses sentinel `clear*` flags for fields whose "absence" is semantically
  /// meaningful (null != unchanged) so callers can e.g. clear a due date
  /// without passing `null` for "leave as-is".
  IssueData copyWith({
    String? title,
    int? commentCount,
    String? updatedAt,
    bool? closed,
    String? closedAt,
    bool clearClosedAt = false,
    TodoPriority? priority,
    bool clearPriority = false,
    String? dueDate,
    bool clearDueDate = false,
  }) => IssueData(
    id: id,
    number: number,
    title: title ?? this.title,
    commentCount: commentCount ?? this.commentCount,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    closed: closed ?? this.closed,
    closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
    priority: clearPriority ? null : (priority ?? this.priority),
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    projectId: projectId,
    projectItemId: projectItemId,
  );
}
