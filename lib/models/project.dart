import 'package:gh_todos/models/priority.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Project {
  final String id;
  final String name;

  @JsonKey(defaultValue: '')
  final String ownerLogin;

  /// GitHub Project field id of the DATE field that maps to the local
  /// "due date". `null` when no mapping is configured.
  final String? dueDateFieldId;

  /// GitHub Project field id of the SINGLE_SELECT field that maps to the
  /// local priority. `null` when no mapping is configured.
  final String? priorityFieldId;

  /// Mapping from the single-select option id (GitHub Project option id)
  /// to the local [TodoPriority]. Only relevant when [priorityFieldId] is
  /// set. Options not present in the map are treated as "unset".
  @JsonKey(defaultValue: <String, TodoPriority>{})
  final Map<String, TodoPriority> priorityOptionMap;

  const Project({
    required this.id,
    required this.name,
    required this.ownerLogin,
    this.dueDateFieldId,
    this.priorityFieldId,
    this.priorityOptionMap = const {},
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? dueDateFieldId,
    String? priorityFieldId,
    Map<String, TodoPriority>? priorityOptionMap,
    bool clearDueDate = false,
    bool clearPriority = false,
  }) => Project(
    id: id,
    name: name,
    ownerLogin: ownerLogin,
    dueDateFieldId: clearDueDate
        ? null
        : (dueDateFieldId ?? this.dueDateFieldId),
    priorityFieldId: clearPriority
        ? null
        : (priorityFieldId ?? this.priorityFieldId),
    priorityOptionMap: clearPriority
        ? const {}
        : (priorityOptionMap ?? this.priorityOptionMap),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
