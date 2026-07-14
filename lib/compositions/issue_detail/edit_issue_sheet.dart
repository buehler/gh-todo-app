import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/adaptive_sheet.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet/priority_level_chip.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Result from the Edit Issue sheet. Captures the intended post-state — the
/// page dispatches the right mutations from this (not every field maps to
/// `updateIssue`; priority + due date live on the project-item node).
class EditIssueResult {
  final String title;
  final String body;
  final bool titleChanged;
  final bool bodyChanged;

  /// `null` means: no mapping configured OR user didn't touch the field
  /// (in combination with [dueDateChanged]).
  final String? dueDate;

  /// Set when the user explicitly cleared the due date.
  final bool dueDateCleared;
  final bool dueDateChanged;

  final TodoPriority? priority;
  final bool priorityCleared;
  final bool priorityChanged;

  const EditIssueResult({
    required this.title,
    required this.body,
    required this.titleChanged,
    required this.bodyChanged,
    required this.dueDate,
    required this.dueDateCleared,
    required this.dueDateChanged,
    required this.priority,
    required this.priorityCleared,
    required this.priorityChanged,
  });

  bool get hasAnyChange =>
      titleChanged || bodyChanged || dueDateChanged || priorityChanged;
}

/// Opens the Edit Issue bottom sheet. [currentBody] is passed in rather than
/// fetched inside the sheet so the sheet stays read-through-friendly (parent
/// already consumes `issueDetailsProvider`). [project] supplies the
/// priority/due-date mappings — when its relevant field id is `null`, the
/// corresponding section is hidden entirely.
Future<EditIssueResult?> showEditIssueSheet(
  BuildContext context, {
  required IssueData issue,
  required String? currentBody,
  required Project? project,
}) {
  return showAdaptiveSheet<EditIssueResult>(
    context,
    dialogMaxWidth: 640,
    builder: (_, isDialog) => _EditIssueSheet(
      issue: issue,
      initialBody: currentBody ?? '',
      project: project,
      isDialog: isDialog,
    ),
  );
}

class _EditIssueSheet extends ConsumerStatefulWidget {
  final IssueData issue;
  final String initialBody;
  final Project? project;
  final bool isDialog;

  const _EditIssueSheet({
    required this.issue,
    required this.initialBody,
    required this.project,
    required this.isDialog,
  });

  @override
  ConsumerState<_EditIssueSheet> createState() => _EditIssueSheetState();
}

class _EditIssueSheetState extends ConsumerState<_EditIssueSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.issue.title,
  );
  late final TextEditingController _bodyController = TextEditingController(
    text: widget.initialBody,
  );

  late DateTime? _dueDate = _parseDueDate(widget.issue.dueDate);
  late TodoPriority? _priority = widget.issue.priority;

  static DateTime? _parseDueDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  bool get _showDueDate => widget.project?.dueDateFieldId != null;

  bool get _showPriority {
    final p = widget.project;
    return p?.priorityFieldId != null && p!.priorityOptionMap.isNotEmpty;
  }

  /// The set of priorities the project maps (only these can be picked).
  List<TodoPriority> get _mappedPriorities {
    final p = widget.project;
    if (p == null) return const [];
    // De-duplicate while preserving enum order for predictable UI.
    final mapped = p.priorityOptionMap.values.toSet();
    return TodoPriority.values.where(mapped.contains).toList(growable: false);
  }

  String get _title => _titleController.text.trim();
  String get _body => _bodyController.text;

  bool get _titleValid => _title.isNotEmpty;

  bool get _titleChanged => _title != widget.issue.title.trim();
  bool get _bodyChanged => _body != widget.initialBody;

  bool get _dueDateChanged {
    final initial = _parseDueDate(widget.issue.dueDate);
    return !_datesEqual(initial, _dueDate);
  }

  bool get _priorityChanged => _priority != widget.issue.priority;

  bool get _canSave =>
      _titleValid &&
      (_titleChanged || _bodyChanged || _dueDateChanged || _priorityChanged);

  static bool _datesEqual(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = _dueDate != null && !_dueDate!.isBefore(today)
        ? _dueDate!
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _dueDate = null);
  }

  void _save() {
    final initialDueIso = widget.issue.dueDate;
    final nextDueIso = _dueDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(_dueDate!);

    Navigator.pop(
      context,
      EditIssueResult(
        title: _title,
        body: _body,
        titleChanged: _titleChanged,
        bodyChanged: _bodyChanged,
        dueDate: nextDueIso,
        dueDateCleared: _dueDateChanged && nextDueIso == null,
        dueDateChanged: _dueDateChanged,
        priority: _priority,
        priorityCleared: _priorityChanged && _priority == null,
        priorityChanged: _priorityChanged,
      ),
    );
    // Reference initialDueIso to keep linter quiet in case of unused-variable
    // false positives across branches above.
    assert(initialDueIso == initialDueIso);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogBody(context);
    }
    return _buildSheetBody(context);
  }

  Widget _buildFormColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(issue: widget.issue),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Title'),
        const SizedBox(height: 8),
        EditorialTextField(
          controller: _titleController,
          hintText: 'Issue title',
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Description'),
        const SizedBox(height: 8),
        EditorialTextField(
          controller: _bodyController,
          hintText: 'Describe the issue…',
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          inputFormatters: const [MarkdownListContinuationFormatter()],
          minLines: 4,
          maxLines: 10,
        ),
        if (_showDueDate) ...[
          const SizedBox(height: 24),
          _DueDateSection(
            selected: _dueDate,
            onPick: _pickDate,
            onClear: _clearDate,
          ),
        ],
        if (_showPriority) ...[
          const SizedBox(height: 24),
          _PrioritySection(
            priorities: _mappedPriorities,
            selected: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: EditorialButton(
                label: 'Cancel',
                variation: ButtonVariation.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EditorialButton(
                label: 'Save',
                enabled: _canSave,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogBody(BuildContext context) {
    // Dialog: adapter provides rounded surface. Column + scrollable inner
    // region fills the adapter's maxHeight cap.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: _buildFormColumn(),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetBody(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdaptiveSheetDragHandle(isDialog: false),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormColumn(),
                        SizedBox(height: MediaQuery.paddingOf(context).bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final IssueData issue;

  const _Header({required this.issue});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StyledText(
          'Edit Issue',
          style: editorialTextStyle(
            TextTokens.title.$large,
            color: onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        StyledText(
          '#${issue.number}',
          style: editorialTextStyle(
            TextTokens.body.$medium,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final outline = resolveColor(context, ColorTokens.outline.$default);
    return StyledText(
      label,
      style: editorialTextStyle(
        TextTokens.label.$small,
        color: outline,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ).uppercase(),
    );
  }
}

class _DueDateSection extends StatelessWidget {
  final DateTime? selected;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DueDateSection({
    required this.selected,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);

    final label = selected == null
        ? 'No due date'
        : formatDueDate(DateFormat('yyyy-MM-dd').format(selected!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(label: 'Due date'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceLow,
            borderRadius: BorderRadius.circular(editorialRadiusSmall),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.calendarClock,
                color: selected == null ? onSurfaceVariant : onSurface,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: resolveTextStyle(context, TextTokens.body.$medium)
                      .copyWith(
                        color: selected == null ? onSurfaceVariant : onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              TextButton(
                onPressed: onPick,
                child: Text(selected == null ? 'Pick date' : 'Change'),
              ),
              if (selected != null)
                TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrioritySection extends StatelessWidget {
  final List<TodoPriority> priorities;
  final TodoPriority? selected;
  final ValueChanged<TodoPriority?> onChanged;

  const _PrioritySection({
    required this.priorities,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    final textStyle = resolveTextStyle(
      context,
      TextTokens.body.$medium,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w600);
    final noneStyle = textStyle.copyWith(
      color: onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    // Defensive: if the currently-selected priority isn't in the mapped list
    // (option remapped remotely), fall back to null so the dropdown doesn't
    // assert.
    final validSelection = selected != null && priorities.contains(selected)
        ? selected
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(label: 'Priority'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: surfaceLow,
            borderRadius: BorderRadius.circular(editorialRadiusSmall),
            border: Border.all(color: withOpacity(outlineVariant, 0.15)),
          ),
          child: DropdownButton<TodoPriority?>(
            value: validSelection,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: textStyle,
            dropdownColor: surfaceLow,
            borderRadius: BorderRadius.circular(editorialRadiusSmall),
            items: [
              DropdownMenuItem<TodoPriority?>(
                value: null,
                child: Text('(None)', style: noneStyle),
              ),
              for (final p in priorities)
                DropdownMenuItem<TodoPriority?>(
                  value: p,
                  child: Row(
                    children: [
                      PriorityLevelChip(priority: p, compact: true),
                      const SizedBox(width: 10),
                      Text(priorityLabels[p]!, style: textStyle),
                    ],
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
