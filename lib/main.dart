import 'package:flutter/widgets.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionController = AppSessionController(
    storageService: GithubTokenStorageService(),
  );
  await sessionController.hydrate();

  final prefs = await SharedPreferences.getInstance();
  final projectStorage = ProjectStorageService(prefs);

  runApp(
    GhTodosApp(
      sessionController: sessionController,
      projectStorage: projectStorage,
    ),
  );
}
