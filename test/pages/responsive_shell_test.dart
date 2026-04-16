import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_nav_rail.dart';
import 'package:gh_todos/compositions/shell/todos_split_view.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

/// Wide-layout smoke tests — the breakpoint system, side nav rail, and
/// split-view detail pane all flip on at `width ≥ 900`. Flutter's widget
/// tester ignores `setSurfaceSize` for `MediaQuery.sizeOf` reads, so we
/// force the viewport using [MediaQuery] directly.
void main() {
  testWidgets('wide viewport renders nav rail instead of bottom tabs', (
    tester,
  ) async {
    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1280, 900)),
        child: ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              GithubTokenStorageService(storage: fakeStorage),
            ),
            sharedPreferencesProvider.overrideWith((_) async => prefs),
            projectListProvider.overrideWith(() => _EmptyProjectList()),
          ],
          child: const GhTodosApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppNavRail.pageKey), findsOneWidget);
    expect(find.byKey(AppBottomNav.pageKey), findsNothing);
  });

  testWidgets('narrow viewport renders bottom tabs instead of nav rail', (
    tester,
  ) async {
    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              GithubTokenStorageService(storage: fakeStorage),
            ),
            sharedPreferencesProvider.overrideWith((_) async => prefs),
            projectListProvider.overrideWith(() => _EmptyProjectList()),
          ],
          child: const GhTodosApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppBottomNav.pageKey), findsOneWidget);
    expect(find.byKey(AppNavRail.pageKey), findsNothing);
  });

  testWidgets('wide todos branch wraps in TodosSplitView with empty detail',
      (tester) async {
    final fakeStorage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1280, 900)),
        child: ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              GithubTokenStorageService(storage: fakeStorage),
            ),
            sharedPreferencesProvider.overrideWith((_) async => prefs),
            projectListProvider.overrideWith(() => _EmptyProjectList()),
          ],
          child: const GhTodosApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(TodosSplitView.pageKey), findsOneWidget);
    expect(find.byKey(TodosSplitView.detailPaneKey), findsOneWidget);
    expect(find.byKey(TodosSplitView.detailPaneEmptyKey), findsOneWidget);
    expect(find.text('Select an issue'), findsOneWidget);
  });
}

class _EmptyProjectList extends ProjectList {
  @override
  List<Project> build() => const [];
}
