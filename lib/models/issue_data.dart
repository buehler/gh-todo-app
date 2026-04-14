import 'package:json_annotation/json_annotation.dart';

part 'issue_data.g.dart';

@JsonSerializable()
class IssueData {
  final String id;
  final int number;
  final String title;
  final int commentCount;
  final String createdAt;

  const IssueData({
    required this.id,
    required this.number,
    required this.title,
    required this.commentCount,
    required this.createdAt,
  });

  factory IssueData.fromJson(Map<String, dynamic> json) =>
      _$IssueDataFromJson(json);

  Map<String, dynamic> toJson() => _$IssueDataToJson(this);
}
