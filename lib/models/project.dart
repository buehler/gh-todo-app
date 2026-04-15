import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gh_todos/models/priority.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// A GitHub Project V2 mapped into the app, plus the optional single-select
/// and date field mappings that power local priority / due-date semantics.
@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    @Default('') String ownerLogin,

    /// GitHub Project field id of the DATE field that maps to the local
    /// "due date". `null` when no mapping is configured.
    String? dueDateFieldId,

    /// GitHub Project field id of the SINGLE_SELECT field that maps to the
    /// local priority. `null` when no mapping is configured.
    String? priorityFieldId,

    /// Mapping from single-select option id (GitHub Project option id) to
    /// the local [TodoPriority]. Only relevant when [priorityFieldId] is
    /// set. Options not present in the map are treated as "unset".
    @Default(<String, TodoPriority>{})
    Map<String, TodoPriority> priorityOptionMap,
  }) = _Project;

  factory Project.fromJson(Map<String, Object?> json) =>
      _$ProjectFromJson(json);
}
