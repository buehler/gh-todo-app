import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/todos/swipeable_issue_row.dart';
import 'package:gh_todos/compositions/todos/todos_issue_composer.dart';
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
    // No project selected → no composer.
    expect(find.byType(TodosIssueComposer), findsNothing);
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
            () => _FakeProjectIssues(
              seed: (open: _testIssues, closed: <IssueData>[]),
            ),
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

  testWidgets(
    'android compact layout keeps pull-to-refresh and hides manual refresh',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await _pumpFeed(
          tester,
          projects: _testProjects,
          open: _testIssues,
          closed: const [],
          mutations: FakeIssueMutations(),
          size: const Size(430, 932),
        );

        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(find.byKey(RootPage.refreshButtonKey), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('android tablet landscape keeps pull-to-refresh in split view', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _pumpFeed(
        tester,
        projects: _testProjects,
        open: _testIssues,
        closed: const [],
        mutations: FakeIssueMutations(),
        size: const Size(1180, 820),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byKey(RootPage.refreshButtonKey), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'desktop layout shows manual refresh instead of pull-to-refresh',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pumpFeed(
          tester,
          projects: _testProjects,
          open: _testIssues,
          closed: const [],
          mutations: FakeIssueMutations(),
          size: const Size(1200, 900),
        );

        expect(find.byType(RefreshIndicator), findsNothing);
        expect(find.byKey(RootPage.refreshButtonKey), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'desktop manual refresh re-fetches issues and shows loading state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final fakeStorage = FakeFlutterSecureStorage(
        seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      var buildCount = 0;
      final completers = <Completer<ProjectIssuesFeed>>[];

      try {
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
                () => _TrackedProjectIssues(
                  onBuild: () => buildCount++,
                  load: () {
                    final completer = Completer<ProjectIssuesFeed>();
                    completers.add(completer);
                    return completer.future;
                  },
                ),
              ),
              issueMutationsProvider.overrideWithValue(FakeIssueMutations()),
            ],
            child: const GhTodosApp(),
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(completers, hasLength(1));
        completers[0].complete((
          open: _testIssues,
          closed: const <IssueData>[],
        ));
        await tester.pumpAndSettle();

        expect(buildCount, 1);
        expect(find.byKey(RootPage.refreshButtonKey), findsOneWidget);
        expect(find.byKey(RootPage.refreshProgressKey), findsNothing);

        await tester.tap(find.byKey(RootPage.refreshButtonKey));
        await tester.pump();

        expect(buildCount, 2);
        expect(completers, hasLength(2));
        expect(find.byKey(RootPage.refreshButtonKey), findsNothing);
        expect(find.byKey(RootPage.refreshProgressKey), findsOneWidget);

        completers[1].complete((
          open: _testIssues,
          closed: const <IssueData>[],
        ));
        await tester.pumpAndSettle();

        expect(find.byKey(RootPage.refreshButtonKey), findsOneWidget);
        expect(find.byKey(RootPage.refreshProgressKey), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('tapping settings tab swaps the branch and back', (tester) async {
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

    await tester.tap(find.byKey(AppBottomNav.settingsTabKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(find.text('GitHub Todos'), findsOneWidget);

    await tester.tap(find.byKey(AppBottomNav.todosTabKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
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

  // ----------------------- Optimistic feed updates --------------------------

  testWidgets(
    'applyClose on the notifier moves the card to "Recently closed"',
    (tester) async {
      await _pumpFeed(
        tester,
        projects: _testProjects,
        open: [_testIssues.first],
        closed: const [],
        mutations: FakeIssueMutations(),
      );

      // No "Recently closed" section yet — the feed is all-open.
      expect(find.byKey(RootPage.recentlyClosedHeaderKey), findsNothing);

      // Simulate what `_RealIssueMutations.closeIssue` does after the GitHub
      // mutation resolves — patch the cached feed directly.
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(RootPage.pageKey)),
      );
      container
          .read(projectIssuesProvider('proj-1').notifier)
          .applyClose(
            'issue-1',
            closedAt: '2026-04-20T10:00:00Z',
            updatedAt: '2026-04-20T10:00:00Z',
          );
      await tester.pumpAndSettle();

      // Card shows up under the "Recently closed" header now.
      expect(find.byKey(RootPage.recentlyClosedHeaderKey), findsOneWidget);
      expect(find.text('Fix login flow'), findsOneWidget);
    },
  );

  testWidgets(
    'applyReopen on the notifier moves the card back to the open list',
    (tester) async {
      await _pumpFeed(
        tester,
        projects: _testProjects,
        open: const [],
        closed: const [_closedIssue],
        mutations: FakeIssueMutations(),
      );

      expect(find.byKey(RootPage.recentlyClosedHeaderKey), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byKey(RootPage.pageKey)),
      );
      container
          .read(projectIssuesProvider('proj-1').notifier)
          .applyReopen('issue-closed-1', updatedAt: '2026-04-20T10:00:00Z');
      await tester.pumpAndSettle();

      // "Recently closed" section disappears once the only closed issue
      // reopens; the title remains visible in the open list.
      expect(find.byKey(RootPage.recentlyClosedHeaderKey), findsNothing);
      expect(find.text('Ship onboarding copy'), findsOneWidget);
    },
  );

  testWidgets(
    'applyCreate on the notifier adds the new issue to the open list',
    (tester) async {
      await _pumpFeed(
        tester,
        projects: _testProjects,
        open: const [],
        closed: const [],
        mutations: FakeIssueMutations(),
      );

      expect(find.text('Freshly composed todo'), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.byKey(RootPage.pageKey)),
      );
      container
          .read(projectIssuesProvider('proj-1').notifier)
          .applyCreate(
            const IssueData(
              id: 'issue-new',
              number: 101,
              title: 'Freshly composed todo',
              commentCount: 0,
              createdAt: '2026-04-20T10:00:00Z',
              updatedAt: '2026-04-20T10:00:00Z',
              projectId: 'proj-1',
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Freshly composed todo'), findsOneWidget);
    },
  );
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
  Size size = const Size(1200, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
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
        projectIssuesProvider(projects.first.id).overrideWith(
          () => _FakeProjectIssues(seed: (open: open, closed: closed)),
        ),
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

/// A fake [ProjectIssues] notifier that seeds the feed synchronously without
/// hitting the network. The `apply*` methods are inherited from the real
/// notifier so tests can exercise the optimistic-paint behaviour by invoking
/// the real mutation layer (which calls those methods internally).
class _FakeProjectIssues extends ProjectIssues {
  _FakeProjectIssues({required this.seed});

  final ProjectIssuesFeed seed;

  @override
  Future<ProjectIssuesFeed> build(String projectId) async => seed;
}

class _TrackedProjectIssues extends ProjectIssues {
  final void Function() onBuild;
  final Future<ProjectIssuesFeed> Function() load;

  _TrackedProjectIssues({required this.onBuild, required this.load});

  @override
  Future<ProjectIssuesFeed> build(String projectId) {
    onBuild();
    return load();
  }
}
