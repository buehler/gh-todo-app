import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_metadata_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthMetadata extends _$AuthMetadata {
  @override
  Future<PatAuthMetadata?> build() {
    return ref.watch(authMetadataStorageProvider).read();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authMetadataStorageProvider).read(),
    );
  }

  Future<void> setMetadata(PatAuthMetadata metadata) async {
    await ref.read(authMetadataStorageProvider).save(metadata);
    state = AsyncData(metadata);
  }

  Future<void> clear() async {
    await ref.read(authMetadataStorageProvider).clear();
    state = const AsyncData(null);
  }
}
