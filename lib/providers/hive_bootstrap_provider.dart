import 'package:gh_todos/services/project_storage_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hive_bootstrap_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> hiveBootstrap(Ref ref) async {
  await initHiveForFlutter();

  if (!Hive.isBoxOpen(HiveStore.defaultBoxName)) {
    await Hive.openBox<dynamic>(HiveStore.defaultBoxName);
  }

  if (!Hive.isBoxOpen(ProjectStorageService.boxName)) {
    await Hive.openBox<String>(ProjectStorageService.boxName);
  }

  // GraphQL reads use the default HiveStore box after bootstrap completes.
}
