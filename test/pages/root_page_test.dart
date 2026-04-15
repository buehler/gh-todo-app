import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/todos/swipeable_issue_row.dart';
import 'package:gh_todos/compositions/todos/todos_fab.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_issue_mutations.dart';
import '../support/fakes.dart';

const _testProjects = [
  Project(id: 'proj-1', name: 'Alpha', ownerLogin: 'acme'),
  Project(id: 'proj-2', name: 'Beta', ownerLogin: 'acme'),
];

const _testIssues = [
  IssueData(
    id: 'issue-1',
    number: 42,
    title: 'Fix login flow',
    commentCount: 3,
    createdAt: '2025-04-01T10:00:00Z',
    updatedAt: '2025-04-02T10:00:00Z',
  ),
  IssueData(
    id: 'issue-2',
    number: 99,
    title: 'Add dark mode',
    commentCount: 0,
    createdAt: '2025-03-15T08:00:00Z',
    updatedAt: '2025-03-16T08:00:00Z',
  ),
];

const _closedIssue = IssueData(
  id: 'issue-closed-1',
  number: 7,
  title: 'Ship onboarding copy',
  commentCount: 0,
  createdAt: '2025-02-01T08:00:00Z',
  updatedAt: '2025-02-10T08:00:00Z',
  closed: true,
  closedAt: '2025-02-10T08:00:00Z',
);

void main() {
  testWidgets('shows empty state when no projects are mapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            GithubTokenStorageService(storage: fakeStorage),
          ),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          projectListProvider.overrideWith(() => _FakeProjectList(const [])),
        ],
        child: const GhTodosApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.byKey(RootPage.emptyKey), findsOneWidget);
    expect(
      find.text('Add a project in Settings to get started.'),
      findsOneWidget,
    );
    expect(find.byType(TodosFab), findsOneWidget);
  });

  testWidgets('renders project chips and issues for selected project', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            GithubTokenStorageService(storage: fakeStorage),
          ),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          projectListProvider.overrideWith(
            () => _FakeProjectList(_testProjects),
          ),
          projectIssuesProvider('proj-1').overrideWith(
            (ref) async => (open: _testIssues, closed: <IssueData>[]),
          ),
        ],
        child: const GhTodosApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Project chips rendered.
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    // Issues rendered.
    expect(find.text('Fix login flow'), findsOneWidget);
    expect(find.text('Add dark mode'), findsOneWidget);
    // Comment count shown for issue with comments.
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tapping settings tab swaps the branch and hides FAB', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            GithubTokenStorageService(storage: fakeStorage),
          ),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          projectListProvider.overrideWith(() => _FakeProjectList(const [])),
        ],
        child: const GhTodosApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.byType(TodosFab), findsOneWidget);

    await tester.tap(find.byKey(AppBottomNav.settingsTabKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(find.byType(TodosFab), findsNothing);
    expect(find.text('GitHub Todos'), findsOneWidget);

    await tester.tap(find.byKey(AppBottomNav.todosTabKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.byType(TodosFab), findsOneWidget);
  });

  // --------------------------- Swipe actions --------------------------------

  testWidgets(
    'swiping an open row and tapping Close fires closeIssue mutation',
    (tester) async {
      final mutations = FakeIssueMutations();
      await _pumpFeed(
        tester,
        projects: _testProjects,
        open: [_testIssues.first],
        closed: const [],
        mutations: mutations,
      );

      final row = find.byKey(SwipeableIssueRow.rowKey('issue-1'));
      expect(row, findsOneWidget);

      await tester.drag(row, const Offset(-240, 0));
      await tester.pumpAndSettle();

      final pane = find.byKey(SwipeableIssueRow.actionPaneKey('issue-1'));
      expect(pane, findsOneWidget);

      await tester.tap(pane);
      await tester.pumpAndSettle();

      expect(mutations.calls.length, 1);
      final call = mutations.calls.single;
      expect(call, isA<CloseIssueCall>());
      expect((call as CloseIssueCall).projectId, 'proj-1');
      expect(call.issueId, 'issue-1');
    },
  );

  testWidgets(
    'swiping a closed row and tapping Reopen fires reopenIssue mutation',
    (tester) async {
      final mutations = FakeIssueMutations();
      await _pumpFeed(
        tester,
        projects: _testProjects,
        open: const [],
        closed: const [_closedIssue],
        mutations: mutations,
      );

      final row = find.byKey(SwipeableIssueRow.rowKey('issue-closed-1'));
      expect(row, findsOneWidget);

      await tester.drag(row, const Offset(-240, 0));
      await tester.pumpAndSettle();

      final pane = find.byKey(
        SwipeableIssueRow.actionPaneKey('issue-closed-1'),
      );
      expect(pane, findsOneWidget);

      await tester.tap(pane);
      await tester.pumpAndSettle();

      expect(mutations.calls.length, 1);
      final call = mutations.calls.single;
      expect(call, isA<ReopenIssueCall>());
      expect((call as ReopenIssueCall).projectId, 'proj-1');
      expect(call.issueId, 'issue-closed-1');
    },
  );

  testWidgets('shows SnackBar when close mutation fails', (tester) async {
    final mutations = FakeIssueMutations()..throwNext = true;
    await _pumpFeed(
      tester,
      projects: _testProjects,
      open: [_testIssues.first],
      closed: const [],
      mutations: mutations,
    );

    await tester.drag(
      find.byKey(SwipeableIssueRow.rowKey('issue-1')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SwipeableIssueRow.actionPaneKey('issue-1')));
    await tester.pumpAndSettle();

    expect(find.text('Failed to close the issue.'), findsOneWidget);
  });
}

/// Pumps the full app with the given project + feed data and a
/// [FakeIssueMutations] override. The test surface is made tall enough for
/// the feed to render without scrolling.
Future<void> _pumpFeed(
  WidgetTester tester, {
  required List<Project> projects,
  required List<IssueData> open,
  required List<IssueData> closed,
  required FakeIssueMutations mutations,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fakeStorage = FakeFlutterSecureStorage(
    seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
  );
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(
          GithubTokenStorageService(storage: fakeStorage),
        ),
        sharedPreferencesProvider.overrideWith((_) async => prefs),
        projectListProvider.overrideWith(() => _FakeProjectList(projects)),
        projectIssuesProvider(
          projects.first.id,
        ).overrideWith((ref) async => (open: open, closed: closed)),
        issueMutationsProvider.overrideWithValue(mutations),
      ],
      child: const GhTodosApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// A fake [ProjectList] notifier that returns a fixed list.
class _FakeProjectList extends ProjectList {
  final List<Project> _projects;

  _FakeProjectList(this._projects);

  @override
  List<Project> build() => _projects;
}
