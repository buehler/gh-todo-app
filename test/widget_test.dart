import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('app boots into setup when no token is stored', (tester) async {
    final controller = AppSessionController(
      storageService: GithubTokenStorageService(
        storage: FakeFlutterSecureStorage(),
      ),
    );
    await controller.hydrate();

    await tester.pumpWidget(GhTodosApp(sessionController: controller));
    await tester.pumpAndSettle();

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });
}
