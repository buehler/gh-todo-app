import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/models/authenticated_user_snapshot.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/pages/application_logs_page.dart';
import 'package:gh_todos/pages/changelog_page.dart';
import 'package:gh_todos/components/github_html_body.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/style/themes.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpAuthenticatedAppAt(
    WidgetTester tester,
    String location,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
      initialLocation: location,
    );

    await tester.pumpWidget(result.app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('deep linking to /settings renders in the shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(find.text('GitHub Todos'), findsOneWidget);
  });

  testWidgets('settings page renders account section and add project button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    // Page headline
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.text('Manage your GitHub connection and editorial workflow.'),
      findsOneWidget,
    );

    // Account section — only PAT, no sync frequency
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('GitHub Personal Access Token'), findsOneWidget);
    expect(find.text('Sync Frequency'), findsNothing);
    expect(find.text('Current PAT scopes'), findsOneWidget);
    expect(find.text('View Logs'), findsOneWidget);
    expect(find.text('View Changelog'), findsOneWidget);
    expect(find.text('PAT GUIDANCE'), findsOneWidget);
    expect(find.text('PROJECT GUIDANCE'), findsOneWidget);
    expect(find.text('Required: project'), findsOneWidget);
    expect(find.text('Required: read:org'), findsOneWidget);
    expect(find.text('Project setup requirements'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);

    // Projects section — empty, but add button is present
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('Add Project'), findsOneWidget);
  });

  testWidgets('view logs pushes the application logs page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    await tester.tap(find.text('View Logs'));
    await tester.pumpAndSettle();

    expect(find.byKey(ApplicationLogsPage.pageKey), findsOneWidget);
    expect(find.text('Application Logs'), findsOneWidget);
  });

  testWidgets('view changelog pushes the changelog page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthenticatedAppAt(tester, AppRoutes.settingsPath);

    await tester.tap(find.text('View Changelog'));
    await tester.pumpAndSettle();

    expect(find.byKey(ChangelogPage.pageKey), findsOneWidget);
    expect(find.byType(GithubHtmlBody), findsOneWidget);
    expect(find.text('The changelog could not be loaded.'), findsNothing);
  });

  testWidgets('application logs can scroll without scrollbar errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final lines = List.generate(
      200,
      (index) => '[runtime] log line ${index.toString().padLeft(3, '0')}',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationLogsProvider.overrideWith((_) => Stream.value(lines)),
        ],
        child: octanePrime(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const ApplicationLogsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -300),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('successful PAT update does not show the generic error toast', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final result = await createTestApp(
      tokenSeed: {GithubTokenStorageService.tokenStorageKey: 'token-a'},
      initialLocation: AppRoutes.settingsPath,
      keepGraphqlClientAlive: true,
      authMetadata: _metadata(id: '100', login: 'alpha'),
      githubAuth: _MapGithubAuthService({
        'token-b': _metadata(id: '200', login: 'bravo'),
      }),
    );

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(result.app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('GitHub Personal Access Token'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Token'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'token-b');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Token'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('The token could not be updated.'), findsNothing);
    expect(find.text('Ready for bravo.'), findsOneWidget);
    expect(
      result.storage.values[GithubTokenStorageService.tokenStorageKey],
      'token-b',
    );
  });
}

PatAuthMetadata _metadata({required String id, required String login}) {
  return PatAuthMetadata(
    user: AuthenticatedUserSnapshot(
      id: id,
      login: login,
      name: '$login user',
      avatarUrl: 'https://example.com/$login.png',
    ),
    scopes: PatAuthMetadata.requiredScopes,
    validatedAt: DateTime(2026, 4, 18),
  );
}

class _MapGithubAuthService extends GithubAuthService {
  final Map<String, PatAuthMetadata> _metadataByToken;

  _MapGithubAuthService(this._metadataByToken);

  @override
  Future<PatAuthMetadata> inspectToken(String token) async {
    final metadata = _metadataByToken[token];
    if (metadata == null) {
      throw const InvalidGithubTokenException('unexpected token');
    }
    return metadata;
  }
}
