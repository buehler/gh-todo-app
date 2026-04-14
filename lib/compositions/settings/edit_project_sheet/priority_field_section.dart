import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet/field_dropdown.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet/priority_level_chip.dart';
import 'package:gh_todos/compositions/settings/settings_section_header.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/providers/project_fields_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Section that lets the user map a SINGLE_SELECT project field to the
/// local priority concept, then (per selected option) map each option to
/// one of 5 [TodoPriority] levels.
class PriorityFieldSection extends ConsumerWidget {
  final String projectId;
  final String? selectedFieldId;
  final Map<String, TodoPriority> optionMap;
  final ValueChanged<String?> onFieldChanged;
  final void Function(String optionId, TodoPriority? priority) onOptionChanged;

  const PriorityFieldSection({
    super.key,
    required this.projectId,
    required this.selectedFieldId,
    required this.optionMap,
    required this.onFieldChanged,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(projectFieldsProvider(projectId));

    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 12,
        crossAxis: CrossAxisAlignment.stretch,
      ),
      children: [
        const SettingsSectionHeader(label: 'Priority Field'),
        _Helper(),
        fieldsAsync.when(
          loading: () => const _Skeleton(),
          error: (_, _) => _ErrorRow(
            onRetry: () => ref.invalidate(projectFieldsProvider(projectId)),
          ),
          data: (fields) {
            final selectFields = fields
                .where((f) => f.kind == ProjectFieldKind.singleSelect)
                .toList(growable: false);
            final activeField = selectedFieldId == null
                ? null
                : selectFields.firstWhere(
                    (f) => f.id == selectedFieldId,
                    orElse: () => const ProjectFieldInfo(
                      id: '',
                      name: '',
                      kind: ProjectFieldKind.singleSelect,
                    ),
                  );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldDropdown(
                  fields: selectFields,
                  selectedFieldId: selectedFieldId,
                  onChanged: onFieldChanged,
                ),
                if (activeField != null && activeField.id.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _ScaleLegend(),
                  const SizedBox(height: 20),
                  _OptionMappingList(
                    options: activeField.options,
                    optionMap: optionMap,
                    onOptionChanged: onOptionChanged,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Helper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    return StyledText(
      'Pick a single-select field, then map each option to a priority level.',
      style: editorialTextStyle(
        TextTokens.body.$small,
        color: onSurfaceVariant,
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        border: Border.all(color: withOpacity(outlineVariant, 0.15)),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final error = resolveColor(context, ColorTokens.error.$default);

    return RowBox(
      style: editorialRowStyle(
        spacing: 12,
        mainAxisSize: MainAxisSize.max,
        crossAxis: CrossAxisAlignment.center,
      ),
      children: [
        Expanded(
          child: StyledText(
            'Failed to load project fields.',
            style: editorialTextStyle(
              TextTokens.body.$small,
              color: error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        EditorialButton(
          label: 'Retry',
          variation: ButtonVariation.tertiary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

/// Reference scale showing the 5 local priority levels, so the user can
/// anchor their mapping decisions against a visible legend.
class _ScaleLegend extends StatelessWidget {
  const _ScaleLegend();

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 10,
        crossAxis: CrossAxisAlignment.stretch,
      ),
      children: [
        StyledText(
          'Priority Scale'.toUpperCase(),
          style: editorialTextStyle(
            TextTokens.label.$small,
            color: onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        for (final priority in TodoPriority.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RowBox(
              style: editorialRowStyle(
                spacing: 10,
                mainAxisSize: MainAxisSize.max,
                crossAxis: CrossAxisAlignment.center,
              ),
              children: [
                PriorityLevelChip(priority: priority),
              ],
            ),
          ),
      ],
    );
  }
}

class _OptionMappingList extends StatelessWidget {
  final List<ProjectFieldOption> options;
  final Map<String, TodoPriority> optionMap;
  final void Function(String optionId, TodoPriority? priority) onOptionChanged;

  const _OptionMappingList({
    required this.options,
    required this.optionMap,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    if (options.isEmpty) {
      return StyledText(
        'This field has no options yet.',
        style: editorialTextStyle(
          TextTokens.body.$small,
          color: onSurfaceVariant,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options) ...[
          _OptionMappingRow(
            option: option,
            selected: optionMap[option.id],
            onChanged: (p) => onOptionChanged(option.id, p),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OptionMappingRow extends StatelessWidget {
  final ProjectFieldOption option;
  final TodoPriority? selected;
  final ValueChanged<TodoPriority?> onChanged;

  const _OptionMappingRow({
    required this.option,
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

    return RowBox(
      style: editorialRowStyle(
        spacing: 12,
        mainAxisSize: MainAxisSize.max,
        crossAxis: CrossAxisAlignment.center,
      ),
      children: [
        Expanded(
          child: StyledText(
            option.name,
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        StyledIcon(
          icon: LucideIcons.arrowRight,
          style: editorialIconStyle(color: onSurfaceVariant, size: 16),
        ),
        _PriorityDropdown(selected: selected, onChanged: onChanged),
      ],
    );
  }
}

class _PriorityDropdown extends StatelessWidget {
  final TodoPriority? selected;
  final ValueChanged<TodoPriority?> onChanged;

  const _PriorityDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    final baseTextStyle = resolveTextStyle(
      context,
      TextTokens.body.$small,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w600);

    final unmappedStyle = baseTextStyle.copyWith(
      color: onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        border: Border.all(color: withOpacity(outlineVariant, 0.15)),
      ),
      child: DropdownButton<TodoPriority?>(
        value: selected,
        underline: const SizedBox.shrink(),
        style: baseTextStyle,
        dropdownColor: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        items: [
          DropdownMenuItem<TodoPriority?>(
            value: null,
            child: Text('Unmapped', style: unmappedStyle),
          ),
          for (final priority in TodoPriority.values)
            DropdownMenuItem<TodoPriority?>(
              value: priority,
              child: PriorityLevelChip(priority: priority),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
