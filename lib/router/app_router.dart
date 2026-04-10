import 'package:gh_todos/pages/privacy_policy_page.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/pages/setup/connect_page.dart';
import 'package:gh_todos/pages/terms_of_service_page.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:go_router/go_router.dart';

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
      GoRoute(
        path: AppRoutes.rootPath,
        name: AppRoutes.rootName,
        builder: (context, state) => const RootPage(),
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
