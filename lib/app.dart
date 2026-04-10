import 'package:flutter/material.dart';
import 'package:gh_todos/router/app_router.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/style/themes.dart';

class GhTodosApp extends StatelessWidget {
  final AppSessionController sessionController;
  final String? initialLocation;

  const GhTodosApp({
    required this.sessionController,
    this.initialLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(
      sessionController,
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
