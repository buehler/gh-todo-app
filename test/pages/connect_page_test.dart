import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  Future<({AppSessionController controller, FakeFlutterSecureStorage storage})>
  pumpSetupApp(WidgetTester tester, {bool throwOnWrite = false}) async {
    final storage = FakeFlutterSecureStorage(throwOnWrite: throwOnWrite);
    final controller = AppSessionController(
      storageService: GithubTokenStorageService(storage: storage),
    );
    await controller.hydrate();

    await tester.pumpWidget(GhTodosApp(sessionController: controller));
    await tester.pumpAndSettle();

    return (controller: controller, storage: storage);
  }

  testWidgets('setup page renders hero, form, notice, and footer links', (
    tester,
  ) async {
    await pumpSetupApp(tester);

    expect(find.text('Connect to GitHub'), findsOneWidget);
    expect(find.text('Personal Access Token'), findsOneWidget);
    expect(find.text('How to create one?'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.textContaining('local authentication'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Operational: All Systems Go'), findsOneWidget);
  });

  testWidgets('cta stays disabled while token is empty', (tester) async {
    await pumpSetupApp(tester);

    final button = tester.widget<EditorialButton>(find.byType(EditorialButton));
    expect(button.enabled, isFalse);
  });

  testWidgets('successful submit stores token and navigates to root', (
    tester,
  ) async {
    final result = await pumpSetupApp(tester);

    await tester.enterText(find.byType(TextField), '  ghp_abc123  ');
    await tester.pumpAndSettle();

    var button = tester.widget<EditorialButton>(find.byType(EditorialButton));
    expect(button.enabled, isTrue);

    button.onPressed!.call();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
    expect(
      result.storage.values[GithubTokenStorageService.tokenStorageKey],
      'ghp_abc123',
    );
    expect(result.controller.hasToken, isTrue);
  });

  testWidgets('failed submit shows inline error and stays on setup', (
    tester,
  ) async {
    await pumpSetupApp(tester, throwOnWrite: true);

    await tester.enterText(find.byType(TextField), 'ghp_abc123');
    await tester.pumpAndSettle();
    final button = tester.widget<EditorialButton>(find.byType(EditorialButton));
    button.onPressed!.call();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('The token could not be saved securely. Try again.'),
      findsOneWidget,
    );
    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });
}
