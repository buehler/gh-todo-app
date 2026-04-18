import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/pages/application_logs_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpAuthenticatedAppAt(
    WidgetTester tester,
    String location,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      initialLocation: location,
    );

    await tester.pumpWidget(result.app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('deep linking to /settings renders in the shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(find.text('GitHub Todos'), findsOneWidget);
  });

  testWidgets('settings page renders account section and add project button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    // Page headline
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.text('Manage your GitHub connection and editorial workflow.'),
      findsOneWidget,
    );

    // Account section — only PAT, no sync frequency
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('GitHub Personal Access Token'), findsOneWidget);
    expect(find.text('Sync Frequency'), findsNothing);
    expect(find.text('Current PAT scopes'), findsOneWidget);
    expect(find.text('View Logs'), findsOneWidget);
    expect(find.text('PAT GUIDANCE'), findsOneWidget);
    expect(find.text('PROJECT GUIDANCE'), findsOneWidget);
    expect(find.text('Required: project'), findsOneWidget);
    expect(find.text('Required: read:org'), findsOneWidget);
    expect(find.text('Project setup requirements'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);

    // Projects section — empty, but add button is present
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('Add Project'), findsOneWidget);
  });

  testWidgets('view logs pushes the application logs page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    await tester.tap(find.text('View Logs'));
    await tester.pumpAndSettle();

    expect(find.byKey(ApplicationLogsPage.pageKey), findsOneWidget);
    expect(find.text('Application Logs'), findsOneWidget);
  });
}
