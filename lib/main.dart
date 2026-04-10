import 'package:flutter/widgets.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionController = AppSessionController(
    storageService: GithubTokenStorageService(),
  );
  await sessionController.hydrate();

  runApp(GhTodosApp(sessionController: sessionController));
}
