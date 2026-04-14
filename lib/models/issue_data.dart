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

  /// Resolved local priority when the issue's GitHub Project item has a value
  /// for the mapped single-select field and the selected option is present in
  /// [Project.priorityOptionMap]. `null` otherwise.
  final TodoPriority? priority;

  /// `YYYY-MM-DD` date string when the issue's GitHub Project item has a
  /// value for the mapped date field. `null` otherwise.
  final String? dueDate;

  const IssueData({
    required this.id,
    required this.number,
    required this.title,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
    this.priority,
    this.dueDate,
  });

  factory IssueData.fromJson(Map<String, dynamic> json) =>
      _$IssueDataFromJson(json);

  Map<String, dynamic> toJson() => _$IssueDataToJson(this);
}
