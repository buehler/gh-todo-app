import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shared/offline_notice.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/router/created_todo_route_extra.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';
import 'package:url_launcher/url_launcher.dart';

class NewTodoForm extends ConsumerStatefulWidget {
  static const pageKey = ValueKey('new-todo-form');

  final Project project;
  final bool embedded;

  const NewTodoForm({required this.project, required this.embedded, super.key});

  @override
  ConsumerState<NewTodoForm> createState() => _NewTodoFormState();
}

class _NewTodoFormState extends ConsumerState<NewTodoForm> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  DateTime? _dueDate;
  TodoPriority? _priority;
  IssueData? _unattachedIssue;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  List<TodoPriority> get _mappedPriorities {
    final mapped = widget.project.priorityOptionMap.values.toSet();
    return TodoPriority.values.where(mapped.contains).toList(growable: false);
  }

  bool get _hasPriorityField =>
      widget.project.priorityFieldId != null && _mappedPriorities.isNotEmpty;

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
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  void _cancel() {
    if (_submitting) return;
    context.goNamed(
      AppRoutes.projectName,
      pathParameters: {AppRoutes.projectIdParam: widget.project.id},
    );
  }

  Future<void> _openCreatedIssue() async {
    final uri = Uri.tryParse(_unattachedIssue?.url ?? '');
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _submitting || _unattachedIssue != null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final mutations = ref.read(issueMutationsProvider);
    IssueData issue;
    try {
      issue = await mutations.createIssueInProject(
        projectId: widget.project.id,
        title: title,
        body: _bodyController.text.trim().isEmpty ? null : _bodyController.text,
      );
    } on IssueProjectAttachmentUnknownException catch (error) {
      if (!mounted) return;
      setState(() {
        _unattachedIssue = error.issue;
        _error =
            'The issue was created, but its project attachment could not '
            'be confirmed. Open it in GitHub to check the attachment.';
        _submitting = false;
      });
      return;
    } on NoLinkedRepositoryException {
      if (!mounted) return;
      setState(() {
        _error =
            'This project has no linked repository. Link one in GitHub '
            'before adding a todo.';
        _submitting = false;
      });
      return;
    } on OfflineWriteBlockedException {
      if (!mounted) return;
      setState(() {
        _error = 'Reconnect to create a todo.';
        _submitting = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to create the todo.';
        _submitting = false;
      });
      return;
    }

    final itemId = issue.projectItemId;
    if (itemId == null) {
      if (!mounted) return;
      setState(() {
        _unattachedIssue = issue;
        _error =
            'The issue was created, but its project item is unavailable. '
            'Open it in GitHub to check the project attachment.';
        _submitting = false;
      });
      return;
    }

    final failedFields = <String>[];
    final dueFieldId = widget.project.dueDateFieldId;
    if (_dueDate != null) {
      if (dueFieldId == null) {
        failedFields.add('due date');
      } else {
        final isoDate = DateFormat('yyyy-MM-dd').format(_dueDate!);
        try {
          await mutations.setProjectItemDate(
            projectId: widget.project.id,
            itemId: itemId,
            fieldId: dueFieldId,
            isoDate: isoDate,
          );
          issue = issue.copyWith(dueDate: isoDate);
        } catch (_) {
          failedFields.add('due date');
        }
      }
    }

    final priorityFieldId = widget.project.priorityFieldId;
    if (_priority != null) {
      String? optionId;
      for (final entry in widget.project.priorityOptionMap.entries) {
        if (entry.value == _priority) {
          optionId = entry.key;
          break;
        }
      }
      if (optionId == null || priorityFieldId == null) {
        failedFields.add('priority');
      } else {
        try {
          await mutations.setProjectItemSingleSelect(
            projectId: widget.project.id,
            itemId: itemId,
            fieldId: priorityFieldId,
            optionId: optionId,
          );
          issue = issue.copyWith(priority: _priority);
        } catch (_) {
          failedFields.add('priority');
        }
      }
    }

    if (!mounted) return;
    context.goNamed(
      AppRoutes.issueDetailName,
      pathParameters: {
        AppRoutes.projectIdParam: widget.project.id,
        AppRoutes.issueIdParam: issue.id,
      },
      extra: CreatedTodoRouteExtra(issue: issue, failedFields: failedFields),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(offlineStatusProvider).asData?.value ?? false;
    final canSave =
        _titleController.text.trim().isNotEmpty &&
        !_submitting &&
        !isOffline &&
        _unattachedIssue == null;
    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                key: NewTodoForm.pageKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      EditorialIconButton(
                        icon: LucideIcons.arrowLeft,
                        tooltip: 'Back to project',
                        enabled: !_submitting,
                        onPressed: _cancel,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StyledText(
                          'New todo',
                          style: editorialTextStyle(
                            TextTokens.title.$large,
                            color: resolveColor(
                              context,
                              ColorTokens.surface.on,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StyledText(
                    'In ${widget.project.name}',
                    style: editorialTextStyle(
                      TextTokens.body.$medium,
                      color: resolveColor(
                        context,
                        ColorTokens.surface.onVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isOffline) ...[
                    const OfflineNotice(message: 'Reconnect to add new todos.'),
                    const SizedBox(height: 20),
                  ],
                  EditorialTextField(
                    controller: _titleController,
                    label: 'Title',
                    hintText: 'What needs to be done?',
                    autofocus: true,
                    enabled: !_submitting && _unattachedIssue == null,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  EditorialTextField(
                    controller: _bodyController,
                    label: 'Description',
                    hintText: 'Add details in Markdown…',
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    inputFormatters: const [
                      MarkdownListContinuationFormatter(),
                    ],
                    minLines: 5,
                    maxLines: 12,
                    enabled: !_submitting && _unattachedIssue == null,
                  ),
                  if (widget.project.dueDateFieldId != null) ...[
                    const SizedBox(height: 24),
                    _DueDateInput(
                      date: _dueDate,
                      enabled: !_submitting && _unattachedIssue == null,
                      onPick: _pickDate,
                      onClear: () => setState(() => _dueDate = null),
                    ),
                  ],
                  if (_hasPriorityField) ...[
                    const SizedBox(height: 24),
                    _PriorityInput(
                      priorities: _mappedPriorities,
                      selected: _priority,
                      enabled: !_submitting && _unattachedIssue == null,
                      onChanged: (value) => setState(() => _priority = value),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 24),
                    StyledText(
                      _error!,
                      style: editorialTextStyle(
                        TextTokens.body.$medium,
                        color: resolveColor(
                          context,
                          ColorTokens.error.$default,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_unattachedIssue != null) ...[
                    EditorialButton(
                      label: 'Open issue on GitHub',
                      onPressed: _unattachedIssue?.url == null
                          ? null
                          : _openCreatedIssue,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: EditorialButton(
                          label: 'Cancel',
                          variation: ButtonVariation.secondary,
                          enabled: !_submitting,
                          onPressed: _cancel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: EditorialButton(
                          label: 'Create todo',
                          enabled: canSave,
                          loading: _submitting,
                          onPressed: canSave ? _submit : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: resolveColor(
        context,
        ColorTokens.surface.containerLowest,
      ),
      body: content,
    );
  }
}

class _DueDateInput extends StatelessWidget {
  final DateTime? date;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DueDateInput({
    required this.date,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'No due date'
        : formatDueDate(DateFormat('yyyy-MM-dd').format(date!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Due date'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: resolveColor(context, ColorTokens.surface.containerLow),
            borderRadius: BorderRadius.circular(editorialRadiusSmall),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.calendarClock,
                size: 18,
                color: resolveColor(context, ColorTokens.surface.onVariant),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: resolveTextStyle(context, TextTokens.body.$medium),
                ),
              ),
              EditorialButton(
                label: date == null ? 'Pick date' : 'Change',
                variation: ButtonVariation.tertiary,
                enabled: enabled,
                onPressed: onPick,
              ),
              if (date != null)
                EditorialIconButton(
                  icon: LucideIcons.x,
                  tooltip: 'Clear due date',
                  variation: IconButtonVariation.ghost,
                  enabled: enabled,
                  onPressed: onClear,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityInput extends StatelessWidget {
  final List<TodoPriority> priorities;
  final TodoPriority? selected;
  final bool enabled;
  final ValueChanged<TodoPriority?> onChanged;

  const _PriorityInput({
    required this.priorities,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Priority'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: resolveColor(context, ColorTokens.surface.containerLow),
            borderRadius: BorderRadius.circular(editorialRadiusSmall),
          ),
          child: DropdownButton<TodoPriority?>(
            value: priorities.contains(selected) ? selected : null,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: resolveColor(
              context,
              ColorTokens.surface.containerLow,
            ),
            style: resolveTextStyle(
              context,
              TextTokens.body.$medium,
            ).copyWith(color: resolveColor(context, ColorTokens.surface.on)),
            items: [
              const DropdownMenuItem<TodoPriority?>(
                value: null,
                child: Text('None'),
              ),
              for (final priority in priorities)
                DropdownMenuItem<TodoPriority?>(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: resolveColor(context, tokensFor(priority).fg),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(priorityLabels[priority]!),
                    ],
                  ),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return StyledText(
      label,
      style: editorialTextStyle(
        TextTokens.label.$small,
        color: resolveColor(context, ColorTokens.surface.onVariant),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
