import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/todos/todos_fab.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpAuthenticatedAppAt(
    WidgetTester tester,
    String location,
  ) async {
    final storage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    final controller = AppSessionController(
      storageService: GithubTokenStorageService(storage: storage),
    );
    await controller.hydrate();

    await tester.pumpWidget(
      GhTodosApp(
        sessionController: controller,
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('deep linking to /settings renders the blank body in the shell',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(find.text('GitHub Todos'), findsOneWidget);
    expect(find.byType(TodosFab), findsNothing);
  });
}
