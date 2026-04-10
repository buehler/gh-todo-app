import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, String>? seed,
    String? initialLocation,
  }) async {
    final storage = FakeFlutterSecureStorage(seed: seed);
    final controller = AppSessionController(
      storageService: GithubTokenStorageService(storage: storage),
    );
    await controller.hydrate();

    await tester.pumpWidget(
      GhTodosApp(
        sessionController: controller,
        initialLocation: initialLocation,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('app start with no token lands on setup', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('app start with token lands on root', (tester) async {
    await pumpApp(
      tester,
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
  });

  testWidgets('authenticated navigation to setup redirects to root', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      initialLocation: AppRoutes.setupPath,
    );

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
  });

  testWidgets('unauthenticated navigation to root redirects to setup', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: AppRoutes.rootPath);

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('privacy and terms remain publicly reachable', (tester) async {
    await pumpApp(tester, initialLocation: AppRoutes.privacyPath);
    expect(find.text('Privacy Policy'), findsOneWidget);

    await pumpApp(tester, initialLocation: AppRoutes.termsPath);
    expect(find.text('Terms of Service'), findsOneWidget);
  });
}
