import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/compositions/shell/app_shell.dart';
import 'package:gh_todos/compositions/shell/todos_split_view.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/pages/application_logs_page.dart';
import 'package:gh_todos/pages/issue_detail_page.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:go_router/go_router.dart';

/// A [ChangeNotifier] that fires whenever the session provider changes,
/// bridging Riverpod state into GoRouter's [refreshListenable].
class _SessionRefreshNotifier extends ChangeNotifier {
  _SessionRefreshNotifier(Ref ref) {
    ref.listen(sessionProvider, (previous, next) => notifyListeners());
  }
}

final appRouterProvider = Provider.family<GoRouter, String?>((
  ref,
  initialLocation,
) {
  final refreshNotifier = _SessionRefreshNotifier(ref);

  return GoRouter(
    initialLocation: initialLocation ?? AppRoutes.rootPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isLoaded = session is AsyncData;
      if (!isLoaded) return null;

      final hasToken = session.requireValue.hasToken;
      final path = state.uri.path;
      final isPublicPath =
          path == AppRoutes.setupPath || path == AppRoutes.applicationLogsPath;

      if (!hasToken && !isPublicPath) {
        return AppRoutes.setupPath;
      }

      if (hasToken && path == AppRoutes.setupPath) {
        return AppRoutes.rootPath;
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rootPath,
                name: AppRoutes.rootName,
                builder: (context, state) =>
                    const TodosSplitView(child: RootPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settingsPath,
                name: AppRoutes.settingsName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.applicationLogsPath,
        name: AppRoutes.applicationLogsName,
        builder: (context, state) => const ApplicationLogsPage(),
      ),
      GoRoute(
        path: AppRoutes.setupPath,
        name: AppRoutes.setupName,
        builder: (context, state) => const ConnectPage(),
      ),
      GoRoute(
        path: AppRoutes.issueDetailPath,
        name: AppRoutes.issueDetailName,
        builder: (context, state) => IssueDetailPage(
          issueId: state.pathParameters['id']!,
          issue: state.extra as IssueData,
        ),
      ),
    ],
  );
});
