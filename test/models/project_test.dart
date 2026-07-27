import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/models/project.dart';

void main() {
  test('defaults issue query when reading legacy project JSON', () {
    final project = Project.fromJson({'id': 'project-1', 'name': 'Inbox'});

    expect(project.issueQuery, defaultIssueQuery);
  });

  test('serializes the configured issue query', () {
    const project = Project(
      id: 'project-1',
      name: 'Inbox',
      issueQuery: 'no:assignee',
    );

    expect(project.toJson()['issueQuery'], 'no:assignee');
  });
}
