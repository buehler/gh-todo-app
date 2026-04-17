import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/services/app_logger_service.dart';

final appLogStoreProvider = Provider<AppLogStore>((ref) {
  final store = AppLogStore();
  ref.onDispose(store.dispose);
  return store;
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger(store: ref.watch(appLogStoreProvider));
});

final applicationLogsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(appLogStoreProvider).stream;
});
