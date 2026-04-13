import 'package:gh_todos/providers/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  Future<({bool hasToken})> build() async {
    final storage = ref.watch(tokenStorageProvider);
    final hasToken = await storage.hasToken();
    return (hasToken: hasToken);
  }

  Future<void> setToken(String token) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.saveToken(token);
    state = const AsyncData((hasToken: true));
  }

  Future<String?> readToken() async {
    final storage = ref.read(tokenStorageProvider);
    return storage.readToken();
  }

  Future<void> clearToken() async {
    final storage = ref.read(tokenStorageProvider);
    await storage.clearToken();
    state = const AsyncData((hasToken: false));
  }
}
