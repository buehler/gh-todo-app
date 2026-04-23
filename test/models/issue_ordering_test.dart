import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/issue_ordering.dart';
import 'package:gh_todos/models/priority.dart';

void main() {
  test('open issue ordering prioritizes mapped priority before due date', () {
    final issues = [
      _issue(
        title: 'Soon medium',
        priority: TodoPriority.medium,
        dueDate: '2026-04-21',
      ),
      _issue(
        title: 'Later high',
        priority: TodoPriority.high,
        dueDate: '2026-04-30',
      ),
      _issue(
        title: 'Soon urgent',
        priority: TodoPriority.urgent,
        dueDate: '2026-04-25',
      ),
    ]..sort(compareOpenIssues);

    expect(issues.map((issue) => issue.title), [
      'Soon urgent',
      'Later high',
      'Soon medium',
    ]);
  });

  test('unset priority sorts after explicit medium and before low', () {
    final issues = [
      _issue(title: 'Low', priority: TodoPriority.low),
      _issue(title: 'Unset'),
      _issue(title: 'Medium', priority: TodoPriority.medium),
    ]..sort(compareOpenIssues);

    expect(issues.map((issue) => issue.title), ['Medium', 'Unset', 'Low']);
  });

  test('due date and updatedAt break ties within the same priority rank', () {
    final issues = [
      _issue(
        title: 'Newest no due',
        priority: TodoPriority.high,
        updatedAt: '2026-04-22T12:00:00Z',
      ),
      _issue(
        title: 'Later due',
        priority: TodoPriority.high,
        dueDate: '2026-04-25',
        updatedAt: '2026-04-23T12:00:00Z',
      ),
      _issue(
        title: 'Earlier due',
        priority: TodoPriority.high,
        dueDate: '2026-04-24',
        updatedAt: '2026-04-20T12:00:00Z',
      ),
      _issue(
        title: 'Older no due',
        priority: TodoPriority.high,
        updatedAt: '2026-04-21T12:00:00Z',
      ),
    ]..sort(compareOpenIssues);

    expect(issues.map((issue) => issue.title), [
      'Earlier due',
      'Later due',
      'Newest no due',
      'Older no due',
    ]);
  });

  test('malformed due dates sort as unset due dates', () {
    final issues = [
      _issue(
        title: 'Malformed newer',
        priority: TodoPriority.high,
        dueDate: 'not-a-date',
        updatedAt: '2026-04-22T12:00:00Z',
      ),
      _issue(
        title: 'Valid due',
        priority: TodoPriority.high,
        dueDate: '2026-04-30',
        updatedAt: '2026-04-20T12:00:00Z',
      ),
    ]..sort(compareOpenIssues);

    expect(issues.map((issue) => issue.title), [
      'Valid due',
      'Malformed newer',
    ]);
  });
}

IssueData _issue({
  required String title,
  TodoPriority? priority,
  String? dueDate,
  String updatedAt = '2026-04-20T10:00:00Z',
}) {
  return IssueData(
    id: title,
    number: title.hashCode.abs() % 1000,
    title: title,
    commentCount: 0,
    createdAt: '2026-04-20T08:00:00Z',
    updatedAt: updatedAt,
    priority: priority,
    dueDate: dueDate,
  );
}
