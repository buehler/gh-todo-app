import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpAuthenticatedAppAt(
    WidgetTester tester,
    String location,
  ) async {
    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      initialLocation: location,
    );

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();
  }

  testWidgets('deep linking to /settings renders in the shell', (
    tester,
  ) async {
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

    // Projects section — empty, but add button is present
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('Add Project'), findsOneWidget);
  });
}
