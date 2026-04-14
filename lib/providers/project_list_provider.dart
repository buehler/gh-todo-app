import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_list_provider.g.dart';

@Riverpod(keepAlive: true)
class ProjectList extends _$ProjectList {
  @override
  List<Project> build() {
    final storage = ref.watch(projectStorageProvider);
    return _sorted(storage.readAll());
  }

  List<Project> _sorted(List<Project> projects) {
    return projects.toList()
      ..sort((a, b) {
        final ownerCmp = a.ownerLogin.compareTo(b.ownerLogin);
        if (ownerCmp != 0) return ownerCmp;
        return a.name.compareTo(b.name);
      });
  }

  Future<void> add(Project project) async {
    final storage = ref.read(projectStorageProvider);
    await storage.add(project);
    state = _sorted(storage.readAll());
  }

  Future<void> update(Project project) async {
    final storage = ref.read(projectStorageProvider);
    await storage.update(project);
    state = _sorted(storage.readAll());
  }

  Future<void> remove(String id) async {
    final storage = ref.read(projectStorageProvider);
    await storage.remove(id);
    state = _sorted(storage.readAll());
  }
}
