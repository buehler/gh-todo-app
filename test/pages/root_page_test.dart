import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/todos_split_view.dart';
import 'package:gh_todos/compositions/todos/swipeable_issue_row.dart';
import 'package:gh_todos/compositions/todos/todos_issue_composer.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

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
    url: 'https://github.com/acme/repo/issues/42',
    description: 'Fix the login edge cases.',
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

final _viewer = Query$UserInformation$viewer(
  id: 'user-me',
  avatarUrl: 'https://example.com/me.png',
  name: 'Me',
  login: 'me',
);

void main() {
  testWidgets('shows empty state when no projects are mapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: ProviderScope(
          overrides: [
            hiveBootstrapProvider.overrideWith((_) async {}),
            offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
            tokenStorageProvider.overrideWithValue(
              GithubTokenStorageService(storage: fakeStorage),
            ),
            sessionPrefsProvider.overrideWithValue(FakeSessionPrefsService()),
            projectListProvider.overrideWith(() => _FakeProjectList(const [])),
          ],
          child: const GhTodosApp(),
        ),
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
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 900)),
        child: ProviderScope(
          overrides: [
            hiveBootstrapProvider.overrideWith((_) async {}),
            offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
            tokenStorageProvider.overrideWithValue(
              GithubTokenStorageService(storage: fakeStorage),
            ),
            sessionPrefsProvider.overrideWithValue(
              FakeSessionPrefsService(selectedProjectId: 'proj-1'),
            ),
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

  testWidgets('groups open todos by due-date bucket and hides empty headers', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final issues = [
      _issue(
        id: 'issue-rest',
        title: 'Later backlog',
        dueDate: _dateIso(today.add(const Duration(days: 4))),
      ),
      _issue(
        id: 'issue-tomorrow',
        title: 'Tomorrow follow-up',
        dueDate: _dateIso(today.add(const Duration(days: 1))),
      ),
      _issue(
        id: 'issue-overdue',
        title: 'Expired rollout',
        dueDate: _dateIso(today.subtract(const Duration(days: 1))),
      ),
      _issue(
        id: 'issue-today',
        title: 'Daily triage',
        dueDate: _dateIso(today),
      ),
    ];

    await _pumpFeed(
      tester,
      projects: _testProjects,
      open: issues,
      closed: const [],
      mutations: FakeIssueMutations(),
      size: const Size(1200, 1400),
    );

    expect(find.byKey(RootPage.overdueHeaderKey), findsOneWidget);
    expect(find.byKey(RootPage.todayHeaderKey), findsOneWidget);
    expect(find.byKey(RootPage.tomorrowHeaderKey), findsOneWidget);
    expect(find.byKey(RootPage.restHeaderKey), findsOneWidget);

    _expectVerticalOrder(tester, [
      find.text('Overdue'),
      find.text('Expired rollout'),
      find.text('Today'),
      find.text('Daily triage'),
      find.text('Tomorrow'),
      find.text('Tomorrow follow-up'),
      find.text('Rest'),
      find.text('Later backlog'),
    ]);
  });

  testWidgets('omits empty todo group headers', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _pumpFeed(
      tester,
      projects: _testProjects,
      open: [
        _issue(
          id: 'issue-today',
          title: 'Only today',
          dueDate: _dateIso(today),
        ),
      ],
      closed: const [],
      mutations: FakeIssueMutations(),
    );

    expect(find.byKey(RootPage.overdueHeaderKey), findsNothing);
    expect(find.byKey(RootPage.todayHeaderKey), findsOneWidget);
    expect(find.byKey(RootPage.tomorrowHeaderKey), findsNothing);
    expect(find.byKey(RootPage.restHeaderKey), findsNothing);
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
      expect(find.byKey(RootPage.refreshButtonKey), findsOneWidget);
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
    'switching projects on wide layout clears the selected issue detail',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final fakeStorage = FakeFlutterSecureStorage(
        seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      );

      try {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: ProviderScope(
              overrides: [
                hiveBootstrapProvider.overrideWith((_) async {}),
                offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
                tokenStorageProvider.overrideWithValue(
                  GithubTokenStorageService(storage: fakeStorage),
                ),
                sessionPrefsProvider.overrideWithValue(
                  FakeSessionPrefsService(selectedProjectId: 'proj-1'),
                ),
                projectListProvider.overrideWith(
                  () => _FakeProjectList(_testProjects),
                ),
                projectIssuesProvider('proj-1').overrideWith(
                  () => _FakeProjectIssues(
                    seed: (open: _testIssues, closed: <IssueData>[]),
                  ),
                ),
                projectIssuesProvider('proj-2').overrideWith(
                  () => _FakeProjectIssues(
                    seed: (
                      open: const [
                        IssueData(
                          id: 'issue-3',
                          number: 11,
                          title: 'Plan release notes',
                          commentCount: 0,
                          createdAt: '2025-04-03T10:00:00Z',
                          updatedAt: '2025-04-04T10:00:00Z',
                        ),
                      ],
                      closed: <IssueData>[],
                    ),
                  ),
                ),
                userInfoProvider.overrideWith((_) => Future.value(_viewer)),
                issueCommentsProvider(
                  'issue-1',
                ).overrideWith((ref) => Stream.value(const [])),
                issueMutationsProvider.overrideWithValue(FakeIssueMutations()),
              ],
              child: const GhTodosApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Fix login flow'));
        await tester.pumpAndSettle();

        expect(find.text('Fix the login edge cases.'), findsOneWidget);
        expect(find.byKey(TodosSplitView.detailPaneEmptyKey), findsNothing);

        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();

        expect(find.byKey(TodosSplitView.detailPaneEmptyKey), findsOneWidget);
        expect(find.text('Fix the login edge cases.'), findsNothing);
        expect(find.text('Plan release notes'), findsOneWidget);
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
      var buildCount = 0;
      final completers = <Completer<ProjectIssuesFeed>>[];

      try {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: ProviderScope(
              overrides: [
                hiveBootstrapProvider.overrideWith((_) async {}),
                offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
                tokenStorageProvider.overrideWithValue(
                  GithubTokenStorageService(storage: fakeStorage),
                ),
                sessionPrefsProvider.overrideWithValue(
                  FakeSessionPrefsService(selectedProjectId: 'proj-1'),
                ),
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
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 900)),
        child: ProviderScope(
          overrides: [
            hiveBootstrapProvider.overrideWith((_) async {}),
            offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
            tokenStorageProvider.overrideWithValue(
              GithubTokenStorageService(storage: fakeStorage),
            ),
            sessionPrefsProvider.overrideWithValue(FakeSessionPrefsService()),
            projectListProvider.overrideWith(() => _FakeProjectList(const [])),
          ],
          child: const GhTodosApp(),
        ),
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
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: ProviderScope(
        overrides: [
          hiveBootstrapProvider.overrideWith((_) async {}),
          offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
          tokenStorageProvider.overrideWithValue(
            GithubTokenStorageService(storage: fakeStorage),
          ),
          sessionPrefsProvider.overrideWithValue(
            FakeSessionPrefsService(selectedProjectId: projects.first.id),
          ),
          projectListProvider.overrideWith(() => _FakeProjectList(projects)),
          projectIssuesProvider(projects.first.id).overrideWith(
            () => _FakeProjectIssues(seed: (open: open, closed: closed)),
          ),
          issueMutationsProvider.overrideWithValue(mutations),
        ],
        child: const GhTodosApp(),
      ),
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
  Stream<ProjectIssuesFeed> build(String projectId) => Stream.value(seed);
}

class _TrackedProjectIssues extends ProjectIssues {
  final void Function() onBuild;
  final Future<ProjectIssuesFeed> Function() load;

  _TrackedProjectIssues({required this.onBuild, required this.load});

  @override
  Stream<ProjectIssuesFeed> build(String projectId) {
    onBuild();
    return Stream.fromFuture(load());
  }
}

class _FakeOfflineStatus extends OfflineStatus {
  @override
  Future<bool> build() async => false;
}

IssueData _issue({required String id, required String title, String? dueDate}) {
  return IssueData(
    id: id,
    number: id.hashCode.abs() % 1000,
    title: title,
    commentCount: 0,
    createdAt: '2026-04-20T08:00:00Z',
    updatedAt: '2026-04-20T10:00:00Z',
    dueDate: dueDate,
  );
}

String _dateIso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

void _expectVerticalOrder(WidgetTester tester, List<Finder> finders) {
  var previousY = double.negativeInfinity;
  for (final finder in finders) {
    expect(finder, findsOneWidget);
    final y = tester.getTopLeft(finder).dy;
    expect(y, greaterThan(previousY));
    previousY = y;
  }
}
