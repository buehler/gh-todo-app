import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_project_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedProject extends _$SelectedProject {
  @override
  Future<String?> build() async {
    final prefs = ref.watch(sessionPrefsProvider);
    final stored = await prefs.readSelectedProjectId();

    final projects = ref.watch(projectListProvider);
    if (stored != null && projects.any((p) => p.id == stored)) {
      return stored;
    }

    final fallback = projects.isNotEmpty ? projects.first.id : null;
    if (fallback == null) {
      await prefs.clearSelectedProjectId();
      return null;
    }

    await prefs.saveSelectedProjectId(fallback);
    return fallback;
  }

  Future<void> select(String id) async {
    final prefs = ref.read(sessionPrefsProvider);
    await prefs.saveSelectedProjectId(id);
    state = AsyncData(id);
  }
}
