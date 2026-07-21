import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  return runApp(ProviderScope(child: const GhTodosApp()));

  // await runZonedGuarded(
  //   () async {
  //     WidgetsFlutterBinding.ensureInitialized();
  //     final container = ProviderContainer();
  //     final logger = container.read(appLoggerProvider);

  //     FlutterError.onError = (details) {
  //       FlutterError.presentError(details);
  //       unawaited(
  //         logger.error(
  //           'Uncaught Flutter framework error.',
  //           category: 'runtime',
  //           error: details.exception,
  //           stackTrace: details.stack,
  //         ),
  //       );
  //     };

  //     PlatformDispatcher.instance.onError = (error, stackTrace) {
  //       unawaited(
  //         logger.error(
  //           'Uncaught platform error.',
  //           category: 'runtime',
  //           error: error,
  //           stackTrace: stackTrace,
  //         ),
  //       );
  //       return true;
  //     };

  //     unawaited(_writeStartupLog(logger));

  //     runApp(
  //       UncontrolledProviderScope(
  //         container: container,
  //         child: const GhTodosApp(),
  //       ),
  //     );
  //   },
  //   (error, stackTrace) async {
  //     WidgetsFlutterBinding.ensureInitialized();
  //     final container = ProviderContainer();
  //     final logger = container.read(appLoggerProvider);
  //     await logger.error(
  //       'Uncaught zoned bootstrap error.',
  //       category: 'runtime',
  //       error: error,
  //       stackTrace: stackTrace,
  //     );
  //   },
  // );
}

// Future<void> _writeStartupLog(AppLogger logger) async {
//   try {
//     await logger.info('Application bootstrap completed.', category: 'runtime');
//   } catch (_) {
//     // Logging must never prevent the first frame from rendering.
//   }
// }
