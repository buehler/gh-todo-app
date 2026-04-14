import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet/field_dropdown.dart';
import 'package:gh_todos/compositions/settings/settings_section_header.dart';
import 'package:gh_todos/providers/project_fields_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Section that lets the user map a GitHub Projects `DATE` field to the
/// local "due date" concept. Optional: when unset (`null`), the project
/// simply has no due date in the todo list.
class DueDateFieldSection extends ConsumerWidget {
  final String projectId;
  final String? selectedFieldId;
  final ValueChanged<String?> onChanged;

  const DueDateFieldSection({
    super.key,
    required this.projectId,
    required this.selectedFieldId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(projectFieldsProvider(projectId));

    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 10,
        crossAxis: CrossAxisAlignment.stretch,
      ),
      children: [
        const SettingsSectionHeader(label: 'Due Date Field'),
        _Helper(),
        fieldsAsync.when(
          loading: () => const _LoadingRow(),
          error: (_, _) => _ErrorRow(
            onRetry: () => ref.invalidate(projectFieldsProvider(projectId)),
          ),
          data: (fields) {
            final dateFields = fields
                .where((f) => f.kind == ProjectFieldKind.date)
                .toList(growable: false);
            return FieldDropdown(
              fields: dateFields,
              selectedFieldId: selectedFieldId,
              onChanged: onChanged,
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
      'Pick a date field from the project to sort todos by due date.',
      style: editorialTextStyle(
        TextTokens.body.$small,
        color: onSurfaceVariant,
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

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
