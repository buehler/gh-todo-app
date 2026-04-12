// Hard-coded seed data for the todos feed.
//
// Mirrors the content of `design/main.html` so the implementation can be
// visually diffed against the mockup. Replace with a real GitHub-backed
// source when API integration lands.

enum IssuePriority { high, standard, closed }

enum IssueStatus { open, closed, overdue, noDate }

enum IssueTypeTag { bug, core, refactor, highPriority }

enum GroupAccent { tertiary, primary }

class TodoIssue {
  final String id;
  final String title;
  final IssueTypeTag typeTag;
  final IssuePriority priority;
  final IssueStatus status;
  final String? dueLabel;
  final int commentCount;
  final int attachmentCount;
  final List<String> assigneeInitials;

  const TodoIssue({
    required this.id,
    required this.title,
    required this.typeTag,
    required this.priority,
    required this.status,
    this.dueLabel,
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.assigneeInitials = const [],
  });
}

class TodoGroup {
  final String name;
  final GroupAccent accent;
  final List<TodoIssue> issues;

  const TodoGroup({
    required this.name,
    required this.accent,
    required this.issues,
  });

  int get openCount =>
      issues.where((i) => i.status != IssueStatus.closed).length;
}

class TodoProject {
  final String label;

  const TodoProject(this.label);
}

const mockTodoProjects = <TodoProject>[
  TodoProject('All Projects'),
  TodoProject('#design-system'),
  TodoProject('#api-v2-refactor'),
  TodoProject('#mobile-onboarding'),
];

const mockTodoGroups = <TodoGroup>[
  TodoGroup(
    name: 'Design System',
    accent: GroupAccent.tertiary,
    issues: [
      TodoIssue(
        id: 'ds-1',
        title: 'Implement dark mode tonal layering tokens',
        typeTag: IssueTypeTag.highPriority,
        priority: IssuePriority.high,
        status: IssueStatus.open,
        dueLabel: 'Oct 24',
        assigneeInitials: ['AV', 'JM'],
      ),
      TodoIssue(
        id: 'ds-2',
        title: 'Audit button components for accessibility contrast',
        typeTag: IssueTypeTag.refactor,
        priority: IssuePriority.closed,
        status: IssueStatus.closed,
        dueLabel: 'Closed 2h ago',
      ),
    ],
  ),
  TodoGroup(
    name: 'API V2 Refactor',
    accent: GroupAccent.primary,
    issues: [
      TodoIssue(
        id: 'api-1',
        title: 'Fix race condition in webhooks consumer',
        typeTag: IssueTypeTag.bug,
        priority: IssuePriority.standard,
        status: IssueStatus.overdue,
        dueLabel: 'Overdue',
        commentCount: 12,
        attachmentCount: 3,
      ),
      TodoIssue(
        id: 'api-2',
        title: 'Update GraphQL schemas for subscription tiers',
        typeTag: IssueTypeTag.core,
        priority: IssuePriority.standard,
        status: IssueStatus.noDate,
        dueLabel: 'No date',
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Settings page mock data
// ---------------------------------------------------------------------------

const mockMaskedPat = '••••••••••••••••ghp_A7x2';
const mockSyncFrequency = 'Every 15 minutes';

class MockSettingsProject {
  final String name;
  final String branchLabel;
  final int activeIssueCount;
  final String mappedTo;
  final bool enabled;
  final GroupAccent accent;

  const MockSettingsProject({
    required this.name,
    required this.branchLabel,
    required this.activeIssueCount,
    required this.mappedTo,
    required this.enabled,
    required this.accent,
  });
}

const mockSettingsProjects = <MockSettingsProject>[
  MockSettingsProject(
    name: 'editorial-ui-system',
    branchLabel: 'main branch',
    activeIssueCount: 12,
    mappedTo: 'GitHub Milestones',
    enabled: true,
    accent: GroupAccent.primary,
  ),
  MockSettingsProject(
    name: 'core-api-v3',
    branchLabel: 'production',
    activeIssueCount: 4,
    mappedTo: 'Issue Custom Field',
    enabled: true,
    accent: GroupAccent.primary,
  ),
  MockSettingsProject(
    name: 'legacy-dashboard',
    branchLabel: 'archived',
    activeIssueCount: 0,
    mappedTo: '',
    enabled: false,
    accent: GroupAccent.tertiary,
  ),
];

/// Hero summary numbers derived from the seed data.
int get mockActiveIssueCount => mockTodoGroups
    .expand((g) => g.issues)
    .where((i) => i.status != IssueStatus.closed)
    .length;

int get mockActiveProjectCount => mockTodoGroups.length;
