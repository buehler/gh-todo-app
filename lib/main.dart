import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/services/app_logging.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeAppLogging();
  runApp(
    ProviderScope(
      observers: [
        TalkerRiverpodObserver(
          talker: talkerInstance,
          settings: const TalkerRiverpodLoggerSettings(
            printStateFullData: false,
            printFailFullData: false,
          ),
        ),
      ],
      child: const GhTodosApp(),
    ),
  );
}
