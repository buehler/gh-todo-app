import 'package:gh_todos/style/colors.dart';
import 'package:json_annotation/json_annotation.dart';

/// Opinionated local priority scale — 5 levels matching `design/prio.html`
/// §07 Semantics (urgent → trivial). GitHub Project single-select options
/// are mapped onto these values when a project configures a priority field.
@JsonEnum()
enum TodoPriority { urgent, high, medium, low, trivial }

/// Human-readable label for each priority level. Kept in code (not the
/// theme) because the text is fixed copy, not a visual concern.
const priorityLabels = <TodoPriority, String>{
  TodoPriority.urgent: 'Urgent',
  TodoPriority.high: 'High Priority',
  TodoPriority.medium: 'Medium Priority',
  TodoPriority.low: 'Low Priority',
  TodoPriority.trivial: 'Trivial',
};

/// Returns the fg/bg `ColorToken` pair for [priority]. Widgets resolve the
/// actual colors through the Mix theme via `resolveColor(context, ...)`.
PriorityLevelTokens tokensFor(TodoPriority priority) => switch (priority) {
  TodoPriority.urgent => ColorTokens.priority.urgent,
  TodoPriority.high => ColorTokens.priority.high,
  TodoPriority.medium => ColorTokens.priority.medium,
  TodoPriority.low => ColorTokens.priority.low,
  TodoPriority.trivial => ColorTokens.priority.trivial,
};
