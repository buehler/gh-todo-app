import 'dart:convert';

import 'package:gh_todos/models/project.dart';
import 'package:hive/hive.dart';

class ProjectStorageService {
  static const boxName = 'mappedProjects';

  final Box<String> _box;

  ProjectStorageService(this._box);

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
  }

  Future<void> add(Project project) async {
    if (_box.containsKey(project.id)) return;
    await _box.put(project.id, jsonEncode(project.toJson()));
  }

  Future<void> update(Project project) async {
    if (!_box.containsKey(project.id)) return;
    await _box.put(project.id, jsonEncode(project.toJson()));
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}
