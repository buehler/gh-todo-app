import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('app boots into setup when no token is stored', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(ConnectPage.pageKey), findsOneWidget);
  });
}
