import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/todos/todos_fab.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpAuthenticatedApp(WidgetTester tester) async {
    final storage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    final controller = AppSessionController(
      storageService: GithubTokenStorageService(storage: storage),
    );
    await controller.hydrate();

    await tester.pumpWidget(GhTodosApp(sessionController: controller));
    await tester.pumpAndSettle();
  }

  testWidgets('todos page shows hero, chips, group headers and cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedApp(tester);

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.text('GitHub Todos'), findsOneWidget);
    expect(find.text('Hi there.'), findsOneWidget);
    expect(find.text('All Projects'), findsOneWidget);
    expect(find.text('#design-system'), findsOneWidget);
    expect(find.text('Design System'), findsOneWidget);
    expect(find.text('API V2 Refactor'), findsOneWidget);
    expect(
      find.text('Implement dark mode tonal layering tokens'),
      findsOneWidget,
    );
    expect(find.text('Fix race condition in webhooks consumer'), findsOneWidget);
    expect(find.text('TODOS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.byType(TodosFab), findsOneWidget);
  });

  testWidgets('group header renders open counts from mock data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedApp(tester);

    // Design System group has one closed issue → one open.
    expect(find.text('1 OPEN'), findsOneWidget);
    // API V2 group has two open issues.
    expect(find.text('2 OPEN'), findsOneWidget);
  });

  testWidgets('tapping the settings nav tab swaps the branch and hides FAB', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedApp(tester);
    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.byType(TodosFab), findsOneWidget);

    await tester.tap(find.byKey(AppBottomNav.settingsTabKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(find.byType(TodosFab), findsNothing);
    // Top bar is shared, so the label remains.
    expect(find.text('GitHub Todos'), findsOneWidget);

    await tester.tap(find.byKey(AppBottomNav.todosTabKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(find.byType(TodosFab), findsOneWidget);
  });
}
