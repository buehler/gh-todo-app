import 'package:gh_todos/services/app_logger_service.dart';

Future<AppLogSink> createPlatformAppLogSink() async {
  return MemoryAppLogSink();
}
