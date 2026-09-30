import 'package:logging/logging.dart' as dart_log;
import 'package:talker_flutter/talker_flutter.dart';

final Talker talkerInstance = TalkerFlutter.init();

bool _initialized = false;

void initializeAppLogging() {
  if (_initialized) return;
  _initialized = true;

  dart_log.Logger.root.level = dart_log.Level.ALL;
  dart_log.Logger.root.onRecord.listen((record) {
    final message = '[${record.loggerName}] ${record.message}';
    if (record.level >= dart_log.Level.SEVERE && record.error != null) {
      talkerInstance.handle(record.error!, record.stackTrace, message);
      return;
    }

    talkerInstance.log(
      message,
      logLevel: switch (record.level) {
        dart_log.Level.INFO => LogLevel.info,
        dart_log.Level.WARNING => LogLevel.warning,
        dart_log.Level.SEVERE || dart_log.Level.SHOUT => LogLevel.error,
        dart_log.Level.FINE => LogLevel.debug,
        _ => LogLevel.verbose,
      },
      exception: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
