import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/compositions/shell/app_shell.dart';
import 'package:gh_todos/compositions/shell/todos_split_view.dart';
import 'package:gh_todos/pages/changelog_page.dart';
import 'package:gh_todos/pages/issue_route_page.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/app_logging.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:talker_flutter/talker_flutter.dart';

final _logger = Logger('AppRouter');

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
  final normalizedInitialLocation =
      _widgetDeepLinkLocation(initialLocation) ?? initialLocation;

  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    observers: [TalkerRouteObserver(talkerInstance)],
    initialLocation: normalizedInitialLocation ?? AppRoutes.rootPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isLoaded = session is AsyncData;
      if (!isLoaded) return null;

      final widgetLocation = _widgetDeepLinkLocation(state.uri.toString());
      if (widgetLocation != null) {
        _logger.fine('Received widget deep link: ${state.uri}');
        return widgetLocation;
      }

      final hasToken = session.requireValue.hasToken;
      final path = state.uri.path;
      final isPublicPath =
          path == AppRoutes.setupPath ||
          path == AppRoutes.applicationLogsPath ||
          path == AppRoutes.changelogPath;

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
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          hideChromeOnCompact: state.uri.path.contains('/issue/'),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rootPath,
                name: AppRoutes.rootName,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: TodosSplitView(child: RootPage()),
                ),
              ),
              GoRoute(
                path: AppRoutes.projectPath,
                name: AppRoutes.projectName,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: TodosSplitView(
                    child: RootPage(
                      requestedProjectId:
                          state.pathParameters[AppRoutes.projectIdParam],
                      routeRefreshKey:
                          state.uri.queryParameters[AppRoutes.freshQueryParam],
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: AppRoutes.issueDetailPath,
                    name: AppRoutes.issueDetailName,
                    pageBuilder: (context, state) {
                      final child = IssueRoutePage(
                        requestedProjectId:
                            state.pathParameters[AppRoutes.projectIdParam]!,
                        issueId: state.pathParameters[AppRoutes.issueIdParam]!,
                        routeRefreshKey: state
                            .uri
                            .queryParameters[AppRoutes.freshQueryParam],
                      );

                      if (isWide(context)) {
                        return NoTransitionPage(
                          key: state.pageKey,
                          child: child,
                        );
                      }

                      return MaterialPage(key: state.pageKey, child: child);
                    },
                  ),
                ],
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
        builder: (context, state) => TalkerScreen(
          talker: talkerInstance,
          appBarTitle: 'Application Logs',
        ),
      ),
      GoRoute(
        path: AppRoutes.changelogPath,
        name: AppRoutes.changelogName,
        builder: (context, state) => const ChangelogPage(),
      ),
      GoRoute(
        path: AppRoutes.setupPath,
        name: AppRoutes.setupName,
        builder: (context, state) => const ConnectPage(),
      ),
    ],
  );
});

String? _widgetDeepLinkLocation(String? location) {
  if (location == null) return null;
  final uri = Uri.tryParse(location);
  if (uri == null || uri.scheme != 'ghtodos') return null;
  final path = uri.path.isEmpty ? AppRoutes.rootPath : uri.path;
  return Uri(
    path: path,
    queryParameters: {
      ...uri.queryParameters,
      AppRoutes.freshQueryParam: DateTime.now().microsecondsSinceEpoch
          .toString(),
    },
  ).toString();
}
