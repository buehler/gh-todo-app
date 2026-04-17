import 'app_logger_service.dart';
import 'app_log_file_sink_factory_stub.dart'
    if (dart.library.io) 'app_log_file_sink_factory_native.dart' as impl;

Future<AppLogSink> createPlatformAppLogSink() => impl.createPlatformAppLogSink();
