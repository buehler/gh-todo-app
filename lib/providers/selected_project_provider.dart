import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_project_provider.g.dart';

const _storageKey = 'todos.selected_project_id';

@Riverpod(keepAlive: true)
class SelectedProject extends _$SelectedProject {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider).requireValue;
    final stored = prefs.getString(_storageKey);

    // If stored ID is still in the project list, use it.
    final projects = ref.watch(projectListProvider);
    if (stored != null && projects.any((p) => p.id == stored)) {
      return stored;
    }

    // Otherwise fall back to the first project.
    return projects.isNotEmpty ? projects.first.id : null;
  }

  Future<void> select(String id) async {
    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    await prefs.setString(_storageKey, id);
    state = id;
  }
}
