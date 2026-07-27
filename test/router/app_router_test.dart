import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/pages/issue_detail_page.dart';
import 'package:gh_todos/pages/issue_route_page.dart';
import 'package:gh_todos/pages/application_logs_page.dart';
import 'package:gh_todos/pages/changelog_page.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:go_router/go_router.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Widget app) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('app start with no token lands on setup', (tester) async {
    final result = await createTestApp();

    await pumpApp(tester, result.app);

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('app start with token lands on root', (tester) async {
    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );

    await pumpApp(tester, result.app);

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
  });

  testWidgets('authenticated navigation to setup redirects to root', (
    tester,
  ) async {
    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      initialLocation: AppRoutes.setupPath,
    );

    await pumpApp(tester, result.app);

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
  });

  testWidgets('unauthenticated navigation to root redirects to setup', (
    tester,
  ) async {
    final result = await createTestApp(initialLocation: AppRoutes.rootPath);

    await pumpApp(tester, result.app);

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('unauthenticated navigation to logs remains on logs', (
    tester,
  ) async {
    final result = await createTestApp(
      initialLocation: AppRoutes.applicationLogsPath,
    );

    await pumpApp(tester, result.app);

    expect(find.byType(ApplicationLogsPage), findsOneWidget);
    expect(find.text('Application Logs'), findsOneWidget);
    expect(find.byKey(ConnectPage.pageKey), findsNothing);
  });

  testWidgets('unauthenticated navigation to changelog remains on changelog', (
    tester,
  ) async {
    final result = await createTestApp(
      initialLocation: AppRoutes.changelogPath,
    );

    await pumpApp(tester, result.app);

    expect(find.byType(ChangelogPage), findsOneWidget);
    expect(find.byKey(ChangelogPage.pageKey), findsOneWidget);
  });

  testWidgets('setup can push application logs while unauthenticated', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final result = await createTestApp(initialLocation: AppRoutes.setupPath);

    await pumpApp(tester, result.app);
    await tester.tap(find.text('View Logs'));
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationLogsPage), findsOneWidget);
    expect(find.text('Application Logs'), findsOneWidget);
  });

  testWidgets('unknown unauthenticated route redirects to setup', (
    tester,
  ) async {
    final result = await createTestApp(initialLocation: '/privacy');

    await pumpApp(tester, result.app);

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('project deep link opens and persists that project', (
    tester,
  ) async {
    final sessionPrefs = FakeSessionPrefsService(selectedProjectId: 'proj-1');

    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: AppRoutes.projectLocation('proj-2'),
        sessionPrefs: sessionPrefs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beta issue'), findsOneWidget);
    expect(await sessionPrefs.readSelectedProjectId(), 'proj-2');
  });

  testWidgets('project deep link uses no transition page', (tester) async {
    await pumpApp(
      tester,
      _deepLinkApp(initialLocation: AppRoutes.projectLocation('proj-1')),
    );
    await tester.pumpAndSettle();

    final pages = tester
        .widgetList<Navigator>(find.byType(Navigator))
        .expand((navigator) => navigator.pages);

    expect(pages.any((page) => page is NoTransitionPage), isTrue);
  });

  testWidgets('project pills keep navigating after restart', (tester) async {
    final sessionPrefs = FakeSessionPrefsService(selectedProjectId: 'proj-1');

    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: AppRoutes.projectLocation('proj-1'),
        sessionPrefs: sessionPrefs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha issue'), findsOneWidget);
    expect(_currentRoutePath(tester), AppRoutes.projectLocation('proj-1'));

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Beta issue'), findsOneWidget);
    expect(await sessionPrefs.readSelectedProjectId(), 'proj-2');
    expect(_currentRoutePath(tester), AppRoutes.projectLocation('proj-2'));

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha issue'), findsOneWidget);
    expect(await sessionPrefs.readSelectedProjectId(), 'proj-1');
    expect(_currentRoutePath(tester), AppRoutes.projectLocation('proj-1'));

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Beta issue'), findsOneWidget);
    expect(await sessionPrefs.readSelectedProjectId(), 'proj-2');
    expect(_currentRoutePath(tester), AppRoutes.projectLocation('proj-2'));
  });

  testWidgets('missing project deep link falls back to last project', (
    tester,
  ) async {
    final sessionPrefs = FakeSessionPrefsService(selectedProjectId: 'proj-1');

    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: AppRoutes.projectLocation('missing'),
        sessionPrefs: sessionPrefs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha issue'), findsOneWidget);
    expect(find.text('Beta issue'), findsNothing);
    expect(await sessionPrefs.readSelectedProjectId(), 'proj-1');
  });

  testWidgets('issue deep link opens detail without route extra', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: AppRoutes.issueDetailLocation(
          projectId: 'proj-1',
          issueId: 'issue-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(IssueDetailPage.pageKey), findsOneWidget);
    expect(find.text('Alpha issue body.'), findsOneWidget);
  });

  testWidgets('wide issue route uses no transition page', (tester) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 900)),
        child: _deepLinkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha issue'));
    await tester.pumpAndSettle();

    final pages = tester
        .widgetList<Navigator>(find.byType(Navigator))
        .expand((navigator) => navigator.pages);

    expect(
      pages.whereType<NoTransitionPage<dynamic>>().any(
        (page) => page.child is IssueRoutePage,
      ),
      isTrue,
    );
  });

  testWidgets('compact issue route retains its material transition page', (
    tester,
  ) async {
    await pumpApp(tester, _deepLinkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha issue'));
    await tester.pumpAndSettle();

    final pages = tester
        .widgetList<Navigator>(find.byType(Navigator))
        .expand((navigator) => navigator.pages);

    expect(
      pages.whereType<MaterialPage<dynamic>>().any(
        (page) => page.child is IssueRoutePage,
      ),
      isTrue,
    );
  });

  testWidgets('missing issue deep link redirects to project root', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: AppRoutes.issueDetailLocation(
          projectId: 'proj-1',
          issueId: 'missing',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.byKey(IssueDetailPage.pageKey), findsNothing);
    expect(find.text('Alpha issue'), findsOneWidget);
  });

  testWidgets('widget project link refreshes cached project issues', (
    tester,
  ) async {
    final projectIssues = _ProjectIssuesController([
      (open: [_alphaIssue], closed: const []),
      (open: [_alphaIssueFresh], closed: const []),
    ]);

    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: 'ghtodos://local/project/proj-1',
        project1Issues: projectIssues,
        prewarmProjectIds: const ['proj-1'],
      ),
    );
    await tester.pumpAndSettle();

    expect(_currentRoutePath(tester), AppRoutes.projectLocation('proj-1'));
    expect(projectIssues.builds, 2);
    expect(find.text('Alpha issue'), findsNothing);
    expect(find.text('Alpha issue fresh'), findsOneWidget);
  });

  testWidgets('widget issue link refreshes cached issues before detail', (
    tester,
  ) async {
    final projectIssues = _ProjectIssuesController([
      (open: [_alphaIssue], closed: const []),
      (open: [_alphaIssueFresh], closed: const []),
    ]);

    await pumpApp(
      tester,
      _deepLinkApp(
        initialLocation: 'ghtodos://local/project/proj-1/issue/issue-1',
        project1Issues: projectIssues,
        prewarmProjectIds: const ['proj-1'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(IssueDetailPage.pageKey), findsOneWidget);
    expect(find.text('Alpha issue body.'), findsNothing);
    expect(find.text('Fresh issue body.'), findsOneWidget);
    expect(projectIssues.builds, 2);
  });

  testWidgets('in-app issue row navigation does not force refresh', (
    tester,
  ) async {
    final projectIssues = _ProjectIssuesController([
      (open: [_alphaIssue], closed: const []),
      (open: [_alphaIssueFresh], closed: const []),
    ]);

    await pumpApp(tester, _deepLinkApp(project1Issues: projectIssues));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha issue'));
    await tester.pumpAndSettle();

    expect(find.byKey(IssueDetailPage.pageKey), findsOneWidget);
    expect(find.text('Alpha issue body.'), findsOneWidget);
    expect(find.text('Fresh issue body.'), findsNothing);
    expect(projectIssues.builds, 1);
  });

  testWidgets('project chip navigation does not force refresh', (tester) async {
    final betaIssues = _ProjectIssuesController([
      (open: [_betaIssue], closed: const []),
      (open: [_betaIssueFresh], closed: const []),
    ]);

    await pumpApp(tester, _deepLinkApp(project2Issues: betaIssues));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Beta issue'), findsOneWidget);
    expect(find.text('Beta issue fresh'), findsNothing);
    expect(betaIssues.builds, 1);
  });

  testWidgets('tapping an issue navigates to project issue route', (
    tester,
  ) async {
    await pumpApp(tester, _deepLinkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha issue'));
    await tester.pumpAndSettle();

    final routeState = GoRouterState.of(
      tester.element(find.byKey(IssueDetailPage.pageKey)),
    );
    expect(
      routeState.uri.path,
      AppRoutes.issueDetailLocation(projectId: 'proj-1', issueId: 'issue-1'),
    );
  });
}

String _currentRoutePath(WidgetTester tester) {
  final context = tester.element(find.byKey(RootPage.pageKey));
  return GoRouterState.of(context).uri.path;
}

Widget _deepLinkApp({
  String? initialLocation,
  FakeSessionPrefsService? sessionPrefs,
  _ProjectIssuesController? project1Issues,
  _ProjectIssuesController? project2Issues,
  List<String> prewarmProjectIds = const [],
}) {
  final fakeStorage = FakeFlutterSecureStorage(
    seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
  );
  final proj1Issues =
      project1Issues ??
      _ProjectIssuesController([
        (open: [_alphaIssue], closed: const []),
      ]);
  final proj2Issues =
      project2Issues ??
      _ProjectIssuesController([
        (open: [_betaIssue], closed: const []),
      ]);

  return ProviderScope(
    overrides: [
      hiveBootstrapProvider.overrideWith((_) async {}),
      offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
      tokenStorageProvider.overrideWithValue(
        GithubTokenStorageService(storage: fakeStorage),
      ),
      sessionPrefsProvider.overrideWithValue(
        sessionPrefs ?? FakeSessionPrefsService(selectedProjectId: 'proj-1'),
      ),
      projectListProvider.overrideWith(() => _FakeProjectList(_projects)),
      projectIssuesProvider(
        'proj-1',
      ).overrideWith(() => _FakeProjectIssues(controller: proj1Issues)),
      projectIssuesProvider(
        'proj-2',
      ).overrideWith(() => _FakeProjectIssues(controller: proj2Issues)),
      userInfoProvider.overrideWith((_) => Future.value(null)),
      issueCommentsProvider(
        'issue-1',
      ).overrideWith((_) => Stream.value(const [])),
    ],
    child: _PrewarmProjectIssues(
      projectIds: prewarmProjectIds,
      child: GhTodosApp(initialLocation: initialLocation),
    ),
  );
}

const _projects = [
  Project(id: 'proj-1', name: 'Alpha', ownerLogin: 'acme'),
  Project(id: 'proj-2', name: 'Beta', ownerLogin: 'acme'),
];

const _alphaIssue = IssueData(
  id: 'issue-1',
  number: 1,
  title: 'Alpha issue',
  body: 'Alpha issue body.',
  bodyHtml: '<p>Alpha issue body.</p>',
  commentCount: 0,
  createdAt: '2026-04-20T08:00:00Z',
  updatedAt: '2026-04-20T10:00:00Z',
  projectId: 'proj-1',
);

const _alphaIssueFresh = IssueData(
  id: 'issue-1',
  number: 1,
  title: 'Alpha issue fresh',
  body: 'Fresh issue body.',
  bodyHtml: '<p>Fresh issue body.</p>',
  commentCount: 0,
  createdAt: '2026-04-20T08:00:00Z',
  updatedAt: '2026-04-20T11:00:00Z',
  projectId: 'proj-1',
);

const _betaIssue = IssueData(
  id: 'issue-2',
  number: 2,
  title: 'Beta issue',
  commentCount: 0,
  createdAt: '2026-04-20T08:00:00Z',
  updatedAt: '2026-04-20T10:00:00Z',
  projectId: 'proj-2',
);

const _betaIssueFresh = IssueData(
  id: 'issue-2',
  number: 2,
  title: 'Beta issue fresh',
  commentCount: 0,
  createdAt: '2026-04-20T08:00:00Z',
  updatedAt: '2026-04-20T11:00:00Z',
  projectId: 'proj-2',
);

class _FakeProjectList extends ProjectList {
  final List<Project> projects;

  _FakeProjectList(this.projects);

  @override
  List<Project> build() => projects;
}

class _ProjectIssuesController {
  final List<ProjectIssuesFeed> feeds;
  int builds = 0;

  _ProjectIssuesController(this.feeds);

  ProjectIssuesFeed next() {
    final index = builds < feeds.length ? builds : feeds.length - 1;
    builds++;
    return feeds[index];
  }
}

class _PrewarmProjectIssues extends ConsumerWidget {
  final List<String> projectIds;
  final Widget child;

  const _PrewarmProjectIssues({required this.projectIds, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    for (final projectId in projectIds) {
      ref.watch(projectIssuesProvider(projectId));
    }
    return child;
  }
}

class _FakeProjectIssues extends ProjectIssues {
  final _ProjectIssuesController controller;

  _FakeProjectIssues({required this.controller});

  @override
  Future<ProjectIssuesFeed> build(String projectId) async => controller.next();
}

class _FakeOfflineStatus extends OfflineStatus {
  @override
  Future<bool> build() async => false;
}
