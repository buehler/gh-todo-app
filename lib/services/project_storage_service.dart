import 'dart:convert';

import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/services/widget_shared_project_cache.dart';
import 'package:hive_ce/hive.dart';

class ProjectStorageService {
  static const boxName = 'mappedProjects';

  final Box<String> _box;
  final WidgetSharedProjectFileService? _projectFileService;

  ProjectStorageService(
    this._box, {
    WidgetSharedProjectFileService? projectFileService,
  }) : _projectFileService = projectFileService;

  List<Project> readAll() {
    return _box.values
        .map((raw) => Project.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Project> projects) async {
    await _box.clear();
    await _box.putAll({
      for (final project in projects) project.id: jsonEncode(project.toJson()),
    });
    await _updateWidgetCache();
  }

  Future<void> add(Project project) async {
    if (_box.containsKey(project.id)) return;
    await _box.put(project.id, jsonEncode(project.toJson()));
    await _updateWidgetCache();
  }

  Future<void> update(Project project) async {
    if (!_box.containsKey(project.id)) return;
    await _box.put(project.id, jsonEncode(project.toJson()));
    await _updateWidgetCache();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    await _updateWidgetCache();
  }

  Future<void> _updateWidgetCache() async {
    return _projectFileService?.writeProjectsJson('[${_box.values.join(',')}]');
  }

  Future<void> syncWidgetCache() => _updateWidgetCache();
}
