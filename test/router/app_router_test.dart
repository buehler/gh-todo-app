import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

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

  testWidgets('privacy and terms remain publicly reachable', (tester) async {
    var result = await createTestApp(
      initialLocation: AppRoutes.privacyPath,
    );
    await pumpApp(tester, result.app);
    expect(find.text('Privacy Policy'), findsOneWidget);

    result = await createTestApp(initialLocation: AppRoutes.termsPath);
    await pumpApp(tester, result.app);
    expect(find.text('Terms of Service'), findsOneWidget);
  });
}
