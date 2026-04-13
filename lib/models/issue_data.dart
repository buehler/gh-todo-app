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
}
