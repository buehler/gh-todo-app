import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/style/themes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: octanePrime(
            Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('primitive smoke test resolves all components', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            EditorialButton(
              label: 'Get Started',
              leadingIcon: LucideIcons.activity,
              trailingIcon: LucideIcons.arrowRight,
            ),
            SizedBox(height: 12),
            EditorialIconButton(
              icon: LucideIcons.settings,
              tooltip: 'Settings',
            ),
            SizedBox(height: 12),
            EditorialTextField(
              label: 'GitHub Token',
              hintText: 'ghp_xxxxxxxxxxxx',
              prefixIcon: LucideIcons.keyRound,
            ),
            SizedBox(height: 12),
            EditorialSwitch(label: 'Push Notifications', value: true),
            SizedBox(height: 12),
            EditorialRadioOption<String>(
              value: 'prod',
              groupValue: 'prod',
              label: 'Production',
            ),
            SizedBox(height: 12),
            EditorialCard(
              variation: CardVariation.accent,
              child: Text('Refactor Auth Middleware'),
            ),
            SizedBox(height: 12),
            EditorialChip(
              label: 'High Priority',
              variation: ChipVariation.status,
              leadingDotColor: Colors.white,
            ),
            SizedBox(height: 12),
            StatusBlip(),
          ],
        ),
      ),
    );

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(LucideIcons.settings), findsOneWidget);
    expect(find.text('GITHUB TOKEN'), findsOneWidget);
    expect(find.text('Push Notifications'), findsOneWidget);
    expect(find.text('Production'), findsOneWidget);
    expect(find.text('Refactor Auth Middleware'), findsOneWidget);
    expect(find.text('HIGH PRIORITY'), findsOneWidget);
    expect(find.byType(StatusBlip), findsOneWidget);
  });

  testWidgets('button variations render and disabled/loading states behave', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      buildHarness(
        Column(
          children: [
            EditorialButton(
              label: 'Primary',
              leadingIcon: LucideIcons.activity,
              onPressed: () => presses++,
            ),
            const SizedBox(height: 12),
            const EditorialButton(
              label: 'Loading',
              trailingIcon: LucideIcons.arrowRight,
              loading: true,
            ),
            const SizedBox(height: 12),
            const EditorialButton(
              label: 'Disabled',
              enabled: false,
              variation: ButtonVariation.secondary,
            ),
            const SizedBox(height: 12),
            const EditorialButton(
              label: 'Ghost',
              variation: ButtonVariation.tertiary,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Primary'));
    await tester.pump();

    expect(presses, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
  });

  testWidgets('text field focus and error helper content render', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        const EditorialTextField(
          label: 'Access Token',
          hintText: 'ghp_123',
          helperText: 'Use repo and admin:org scopes.',
          prefixIcon: LucideIcons.keyRound,
        ),
      ),
    );

    expect(find.text('Use repo and admin:org scopes.'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );

    await tester.pumpWidget(
      buildHarness(
        const EditorialTextField(
          label: 'Access Token',
          errorText: 'Token is invalid.',
          prefixIcon: LucideIcons.keyRound,
        ),
      ),
    );

    expect(find.text('Token is invalid.'), findsOneWidget);
  });

  testWidgets('switch and radio options update checked state', (tester) async {
    var switchValue = false;
    var radioValue = 'staging';

    await tester.pumpWidget(
      buildHarness(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorialSwitch(
                  label: 'Developer Analytics',
                  value: switchValue,
                  onChanged: (nextValue) {
                    setState(() => switchValue = nextValue);
                  },
                ),
                const SizedBox(height: 12),
                EditorialRadioOption<String>(
                  value: 'production',
                  groupValue: radioValue,
                  label: 'Production',
                  onChanged: (nextValue) {
                    setState(() => radioValue = nextValue);
                  },
                ),
                const SizedBox(height: 12),
                EditorialRadioOption<String>(
                  value: 'staging',
                  groupValue: radioValue,
                  label: 'Staging',
                  onChanged: (nextValue) {
                    setState(() => radioValue = nextValue);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Developer Analytics'));
    await tester.pumpAndSettle();
    expect(switchValue, isTrue);

    await tester.tap(find.text('Production'));
    await tester.pumpAndSettle();
    expect(radioValue, 'production');
  });

  testWidgets('chip selection and accent card render', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      buildHarness(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialChip(label: 'All Projects', selected: true),
            const SizedBox(height: 12),
            EditorialChip(label: '#backend-v2', onPressed: () => tapped = true),
            const SizedBox(height: 12),
            const EditorialChip(
              label: 'hash: e9a2c1f',
              variation: ChipVariation.hash,
              icon: LucideIcons.gitCommitHorizontal,
            ),
            const SizedBox(height: 12),
            const EditorialCard(
              variation: CardVariation.accent,
              child: Text('Accent Card'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('#backend-v2'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
    expect(find.byKey(EditorialCard.accentStripKey), findsOneWidget);
    expect(find.text('hash: e9a2c1f'), findsOneWidget);
  });
}
