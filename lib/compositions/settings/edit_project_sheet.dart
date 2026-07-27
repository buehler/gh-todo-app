import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/adaptive_sheet.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet/due_date_field_section.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet/priority_field_section.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Result returned by [showEditProjectSheet]. `null` means the user dismissed
/// without choosing any action.
sealed class EditProjectResult {
  const EditProjectResult();
}

/// User asked to remove the project mapping entirely.
class RemoveProjectResult extends EditProjectResult {
  const RemoveProjectResult();
}

/// User saved updated field mappings. [project] holds the new state.
class UpdateProjectResult extends EditProjectResult {
  final Project project;

  const UpdateProjectResult(this.project);
}

/// Shows a bottom sheet that lets the user edit a mapped project:
/// - pick an optional DATE field mapping for the local due date
/// - pick an optional SINGLE_SELECT field mapping for the local priority
///   and map each option to one of 5 priority levels
/// - remove the project entirely
///
/// Returns an [EditProjectResult] describing what the caller should do.
Future<EditProjectResult?> showEditProjectSheet(
  BuildContext context,
  Project project,
) {
  // useRootNavigator defaults to true on the adapter, so (on narrow) the sheet
  // (and any DropdownButton overlays it opens) render above AppShell's
  // persistent bottom nav. Without that the branch's nested navigator would
  // sit underneath the nav bar, clipping dropdown options that extend near
  // the bottom.
  return showAdaptiveSheet<EditProjectResult>(
    context,
    dialogMaxWidth: 640,
    builder: (_, isDialog) =>
        _EditProjectSheet(project: project, isDialog: isDialog),
  );
}

class _EditProjectSheet extends ConsumerStatefulWidget {
  final Project project;
  final bool isDialog;

  const _EditProjectSheet({required this.project, required this.isDialog});

  @override
  ConsumerState<_EditProjectSheet> createState() => _EditProjectSheetState();
}

class _EditProjectSheetState extends ConsumerState<_EditProjectSheet> {
  late final TextEditingController _issueQueryController =
      TextEditingController(text: widget.project.issueQuery);
  late String? _dueDateFieldId = widget.project.dueDateFieldId;
  late String? _priorityFieldId = widget.project.priorityFieldId;
  late Map<String, TodoPriority> _priorityOptionMap = Map.of(
    widget.project.priorityOptionMap,
  );

  bool get _isDirty {
    final p = widget.project;
    if (p.issueQuery != _issueQueryController.text.trim()) return true;
    if (p.dueDateFieldId != _dueDateFieldId) return true;
    if (p.priorityFieldId != _priorityFieldId) return true;
    return !_mapsEqual(p.priorityOptionMap, _priorityOptionMap);
  }

  static bool _mapsEqual(
    Map<String, TodoPriority> a,
    Map<String, TodoPriority> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  void _onDueDateFieldChanged(String? fieldId) {
    setState(() => _dueDateFieldId = fieldId);
  }

  @override
  void dispose() {
    _issueQueryController.dispose();
    super.dispose();
  }

  void _onPriorityFieldChanged(String? fieldId) {
    setState(() {
      _priorityFieldId = fieldId;
      // Clearing the field clears the per-option mapping — storing options
      // that belong to an unmapped field would only confuse us later.
      if (fieldId == null) _priorityOptionMap = {};
    });
  }

  void _onPriorityOptionChanged(String optionId, TodoPriority? priority) {
    setState(() {
      final next = Map<String, TodoPriority>.of(_priorityOptionMap);
      if (priority == null) {
        next.remove(optionId);
      } else {
        next[optionId] = priority;
      }
      _priorityOptionMap = next;
    });
  }

  void _save() {
    final updated = Project(
      id: widget.project.id,
      name: widget.project.name,
      ownerLogin: widget.project.ownerLogin,
      issueQuery: _issueQueryController.text.trim(),
      dueDateFieldId: _dueDateFieldId,
      priorityFieldId: _priorityFieldId,
      priorityOptionMap: _priorityFieldId == null
          ? const {}
          : _priorityOptionMap,
    );
    Navigator.pop(context, UpdateProjectResult(updated));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildDialogBody(context);
    return _buildSheetBody(context);
  }

  Widget _buildFormColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(project: widget.project),
        const SizedBox(height: 24),
        EditorialTextField(
          controller: _issueQueryController,
          label: 'Issue Query',
          hintText: defaultIssueQuery,
          helperText: 'GitHub Project query used to filter this todo feed.',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        DueDateFieldSection(
          projectId: widget.project.id,
          selectedFieldId: _dueDateFieldId,
          onChanged: _onDueDateFieldChanged,
        ),
        const SizedBox(height: 28),
        PriorityFieldSection(
          projectId: widget.project.id,
          selectedFieldId: _priorityFieldId,
          optionMap: _priorityOptionMap,
          onFieldChanged: _onPriorityFieldChanged,
          onOptionChanged: _onPriorityOptionChanged,
        ),
        const SizedBox(height: 32),
        _SaveActions(
          isDirty: _isDirty,
          onCancel: () => Navigator.pop(context),
          onSave: _save,
        ),
        const SizedBox(height: 32),
        _RemoveRow(
          onPressed: () => Navigator.pop(context, const RemoveProjectResult()),
        ),
      ],
    );
  }

  Widget _buildDialogBody(BuildContext context) {
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
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Project project;

  const _Header({required this.project});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 4,
        crossAxis: CrossAxisAlignment.start,
      ),
      children: [
        StyledText(
          project.name,
          style: editorialTextStyle(
            TextTokens.title.$large,
            color: onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (project.ownerLogin.isNotEmpty)
          StyledText(
            project.ownerLogin,
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _SaveActions extends StatelessWidget {
  final bool isDirty;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _SaveActions({
    required this.isDirty,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EditorialButton(
            label: 'Cancel',
            variation: ButtonVariation.secondary,
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EditorialButton(
            label: 'Save',
            enabled: isDirty,
            onPressed: isDirty ? onSave : null,
          ),
        ),
      ],
    );
  }
}

class _RemoveRow extends StatelessWidget {
  final VoidCallback onPressed;

  const _RemoveRow({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final error = resolveColor(context, ColorTokens.error.$default);
    final errorContainer = resolveColor(context, ColorTokens.error.container);
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );

    return PressableBox(
      onPress: onPressed,
      style: BoxStyler()
          .color(Colors.transparent)
          .borderRounded(editorialRadiusMedium)
          .paddingOnly(horizontal: 4, vertical: 12)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(surfaceHighest)),
      child: RowBox(
        style: editorialRowStyle(spacing: 16, mainAxisSize: MainAxisSize.max),
        children: [
          Box(
            style: BoxStyler()
                .width(40)
                .height(40)
                .color(withOpacity(errorContainer, 0.3))
                .borderRounded(editorialRadiusSmall)
                .alignment(Alignment.center),
            child: StyledIcon(
              icon: LucideIcons.trash2,
              style: editorialIconStyle(color: error, size: 20),
            ),
          ),
          Expanded(
            child: StyledText(
              'Remove Project',
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
