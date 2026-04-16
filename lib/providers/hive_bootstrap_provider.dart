import 'package:gh_todos/services/project_storage_service.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hive_bootstrap_provider.g.dart';

const kGraphqlCacheBoxName = 'graphqlClientStore';

@Riverpod(keepAlive: true)
Future<void> hiveBootstrap(Ref ref) async {
  if (!Hive.isBoxOpen(kGraphqlCacheBoxName)) {
    await Hive.openBox<dynamic>(kGraphqlCacheBoxName);
  }

  if (!Hive.isBoxOpen(ProjectStorageService.boxName)) {
    await Hive.openBox<String>(ProjectStorageService.boxName);
  }

  // GraphQL reads use the default HiveStore box after bootstrap completes.
}
