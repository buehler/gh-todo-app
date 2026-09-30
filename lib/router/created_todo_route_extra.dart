import 'package:gh_todos/models/issue_data.dart';

/// Transient data for the first detail render after creating a todo.
class CreatedTodoRouteExtra {
  final IssueData issue;
  final List<String> failedFields;

  const CreatedTodoRouteExtra({
    required this.issue,
    required this.failedFields,
  });
}
