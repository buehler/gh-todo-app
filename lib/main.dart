import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initHiveForFlutter();

    final container = ProviderContainer();
    final logger = container.read(appLoggerProvider);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        logger.error(
          'Uncaught Flutter framework error.',
          category: 'runtime',
          error: details.exception,
          stackTrace: details.stack,
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        logger.error(
          'Uncaught platform error.',
          category: 'runtime',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return true;
    };

    await logger.info('Application bootstrap completed.', category: 'runtime');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const GhTodosApp(),
      ),
    );
  }, (error, stackTrace) async {
    WidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    final logger = container.read(appLoggerProvider);
    await logger.error(
      'Uncaught zoned bootstrap error.',
      category: 'runtime',
      error: error,
      stackTrace: stackTrace,
    );
  });
}
