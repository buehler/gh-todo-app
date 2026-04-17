import 'package:gh_todos/services/app_log_file_sink_factory_stub.dart'
    if (dart.library.io) 'app_log_file_sink_factory_native.dart' as impl;
import 'package:gh_todos/services/app_logger_service.dart';

Future<AppLogSink> createPlatformAppLogSink() => impl.createPlatformAppLogSink();
