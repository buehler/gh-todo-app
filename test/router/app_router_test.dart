import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('app start with no token lands on setup', (tester) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('app start with token lands on root', (tester) async {
    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
  });

  testWidgets('authenticated navigation to setup redirects to root', (
    tester,
  ) async {
    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      initialLocation: AppRoutes.setupPath,
    );

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.byKey(RootPage.pageKey), findsOneWidget);
  });

  testWidgets('unauthenticated navigation to root redirects to setup', (
    tester,
  ) async {
    final result = await createTestApp(initialLocation: AppRoutes.rootPath);

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });

  testWidgets('privacy and terms remain publicly reachable', (tester) async {
    var result = await createTestApp(
      initialLocation: AppRoutes.privacyPath,
    );
    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsOneWidget);

    result = await createTestApp(initialLocation: AppRoutes.termsPath);
    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();
    expect(find.text('Terms of Service'), findsOneWidget);
  });
}
