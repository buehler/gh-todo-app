import 'dart:convert';

import 'package:gh_todos/models/project.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectStorageService {
  static const storageKey = 'settings.mapped_projects';

  final SharedPreferences _prefs;

  ProjectStorageService(this._prefs);

  List<Project> readAll() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Project> projects) async {
    final json = jsonEncode(projects.map((p) => p.toJson()).toList());
    await _prefs.setString(storageKey, json);
  }

  Future<void> add(Project project) async {
    final current = readAll();
    if (current.any((p) => p.id == project.id)) return;
    current.add(project);
    await save(current);
  }

  Future<void> update(Project project) async {
    final current = readAll();
    final idx = current.indexWhere((p) => p.id == project.id);
    if (idx == -1) return;
    current[idx] = project;
    await save(current);
  }

  Future<void> remove(String id) async {
    final current = readAll()..removeWhere((p) => p.id == id);
    await save(current);
  }
}
