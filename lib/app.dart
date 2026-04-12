import 'package:flutter/material.dart';
import 'package:gh_todos/router/app_router.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/style/themes.dart';

class GhTodosApp extends StatelessWidget {
  final AppSessionController sessionController;
  final ProjectStorageService projectStorage;
  final String? initialLocation;

  const GhTodosApp({
    required this.sessionController,
    required this.projectStorage,
    this.initialLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(
      sessionController,
      projectStorage: projectStorage,
      initialLocation: initialLocation,
    );

    return octanePrime(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}
