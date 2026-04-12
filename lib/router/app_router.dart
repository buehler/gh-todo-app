import 'package:flutter/cupertino.dart';
import 'package:gh_todos/compositions/shell/app_shell.dart';
import 'package:gh_todos/pages/privacy_policy_page.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/settings_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/pages/terms_of_service_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

GoRouter buildAppRouter(
  AppSessionController sessionController, {
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoutes.rootPath,
    refreshListenable: sessionController,
    redirect: (context, state) {
      if (!sessionController.isHydrated) {
        return null;
      }

      final path = state.uri.path;
      final isPublicPage =
          path == AppRoutes.privacyPath || path == AppRoutes.termsPath;

      if (!sessionController.hasToken &&
          !isPublicPage &&
          path != AppRoutes.setupPath) {
        return AppRoutes.setupPath;
      }

      if (sessionController.hasToken && path == AppRoutes.setupPath) {
        return AppRoutes.rootPath;
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => GraphQLProvider(
          client: ValueNotifier(
            GraphQLClient(
              link: AuthLink(
                getToken: () async =>
                    'Bearer ${await sessionController.readToken()}',
              ).concat(HttpLink('https://api.github.com/graphql')),
              cache: GraphQLCache(),
            ),
          ),
          child: AppShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rootPath,
                name: AppRoutes.rootName,
                builder: (context, state) => const RootPage(),
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
        path: AppRoutes.setupPath,
        name: AppRoutes.setupName,
        builder: (context, state) =>
            ConnectPage(sessionController: sessionController),
      ),
      GoRoute(
        path: AppRoutes.privacyPath,
        name: AppRoutes.privacyName,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.termsPath,
        name: AppRoutes.termsName,
        builder: (context, state) => const TermsOfServicePage(),
      ),
    ],
  );
}
