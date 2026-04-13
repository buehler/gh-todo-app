import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_list_provider.g.dart';

@Riverpod(keepAlive: true)
class ProjectList extends _$ProjectList {
  @override
  List<Project> build() {
    final storage = ref.watch(projectStorageProvider);
    return storage.readAll();
  }

  Future<void> add(Project project) async {
    final storage = ref.read(projectStorageProvider);
    await storage.add(project);
    state = storage.readAll();
  }

  Future<void> remove(String id) async {
    final storage = ref.read(projectStorageProvider);
    await storage.remove(id);
    state = storage.readAll();
  }
}
