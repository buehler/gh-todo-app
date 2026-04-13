import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('app boots into setup when no token is stored', (tester) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });
}
