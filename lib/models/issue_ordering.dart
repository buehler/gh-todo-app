import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/priority.dart';

/// Orders open todos by priority, due date, then recent activity.
///
/// Unmapped priority intentionally sits just below explicit medium, so a
/// user-mapped medium keeps precedence over the default interpretation.
int compareOpenIssues(IssueData a, IssueData b) {
  final priorityCmp = _priorityRank(
    a.priority,
  ).compareTo(_priorityRank(b.priority));
  if (priorityCmp != 0) return priorityCmp;

  final aDue = _parseDueDate(a.dueDate);
  final bDue = _parseDueDate(b.dueDate);
  if (aDue != null || bDue != null) {
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    final dueCmp = aDue.compareTo(bDue);
    if (dueCmp != 0) return dueCmp;
  }

  return b.updatedAt.compareTo(a.updatedAt);
}

int _priorityRank(TodoPriority? priority) => switch (priority) {
  TodoPriority.urgent => 0,
  TodoPriority.high => 1,
  TodoPriority.medium => 2,
  null => 3,
  TodoPriority.low => 4,
  TodoPriority.trivial => 5,
};

DateTime? _parseDueDate(String? dueDate) {
  if (dueDate == null) return null;
  final parsed = DateTime.tryParse(dueDate);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}
