import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/compositions/shared/editorial_text_link.dart';
import 'package:gh_todos/compositions/setup/connect_token_form.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/style/themes.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('setup page renders hero, form, notice, and footer links', (
    tester,
  ) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.text('Connect to GitHub'), findsOneWidget);
    expect(find.text('Personal Access Token'), findsOneWidget);
    expect(find.text('How to create one?'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Personal Access Token requirements'), findsOneWidget);
    expect(find.text('Required: project'), findsOneWidget);
    expect(find.text('Required: repo'), findsOneWidget);
    expect(find.text('Required: read:org'), findsOneWidget);
    expect(find.textContaining('local authentication'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Operational: All Systems Go'), findsOneWidget);
  });

  testWidgets('background stays outside safe area while content stays inside', (
    tester,
  ) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    expect(find.byKey(ConnectPage.backgroundKey), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(ConnectPage.backgroundKey),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byKey(ConnectPage.pageKey),
        matching: find.byKey(ConnectPage.safeAreaKey),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the PAT field focuses it (real hit test)', (
    tester,
  ) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );
  });

  testWidgets(
    'tapping "How to create one?" reaches the help link via hit test',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var helpPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: octanePrime(
              ConnectTokenForm(
                controller: controller,
                onChanged: (_) {},
                onSubmitted: (_) {},
                onConnectPressed: () {},
                onHelpPressed: () => helpPressed = true,
                isSubmitting: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('How to create one?'));
      await tester.pumpAndSettle();

      expect(helpPressed, isTrue);
    },
  );

  testWidgets('cta stays disabled while token is empty', (tester) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

    final button = tester.widget<EditorialButton>(find.byType(EditorialButton));
    expect(button.enabled, isFalse);
  });

  testWidgets('successful submit stores token and navigates to root', (
    tester,
  ) async {
    final result = await createTestApp();

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

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
  });

  testWidgets('failed submit shows inline error and stays on setup', (
    tester,
  ) async {
    final result = await createTestApp(throwOnWrite: true);

    await tester.pumpWidget(result.app);
    await tester.pumpAndSettle();

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

  testWidgets('how to create one link is tappable', (tester) async {
    final controller = TextEditingController();
    var helpPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: octanePrime(
            ConnectTokenForm(
              controller: controller,
              onChanged: (_) {},
              onSubmitted: (_) {},
              onConnectPressed: () {},
              onHelpPressed: () => helpPressed = true,
              isSubmitting: false,
            ),
          ),
        ),
      ),
    );

    final link = tester.widget<EditorialTextLink>(
      find.byType(EditorialTextLink),
    );
    link.onPressed!.call();
    await tester.pump();

    expect(helpPressed, isTrue);
  });
}
