import 'app_logger_service.dart';

Future<AppLogSink> createPlatformAppLogSink() async {
  return MemoryAppLogSink();
}
