import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/providers/auth_metadata_provider.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
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

  Future<void> connectToken(String token) async {
    final manager = ref.read(sessionManagerProvider);
    final metadata = await manager.connectToken(token);
    await ref.read(authMetadataProvider.notifier).setMetadata(metadata);
    state = const AsyncData((hasToken: true));
  }

  Future<void> updateToken(String token) async {
    final manager = ref.read(sessionManagerProvider);
    await manager.updateToken(token);
    _invalidateSessionScopedState();
    state = const AsyncData((hasToken: true));
  }

  Future<String?> readToken() async {
    final storage = ref.read(tokenStorageProvider);
    return storage.readToken();
  }

  Future<void> clearToken() async {
    final manager = ref.read(sessionManagerProvider);
    await manager.clearSessionData();
    _invalidateSessionScopedState();
    state = const AsyncData((hasToken: false));
  }

  void _invalidateSessionScopedState() {
    ref.invalidate(projectListProvider);
    ref.invalidate(selectedProjectProvider);
    ref.invalidate(authMetadataProvider);
    ref.invalidate(graphqlClientProvider);
    ref.invalidate(userInfoProvider);
    ref.invalidate(userOrganizationsProvider);
  }
}
