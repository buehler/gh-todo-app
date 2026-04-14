import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/project_fields_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';

/// Styled dropdown for picking a GitHub Projects V2 field (or none).
///
/// Matches the visual treatment of the owner dropdown in
/// `add_project_sheet.dart` so the two sheets feel like siblings.
class FieldDropdown extends StatelessWidget {
  final List<ProjectFieldInfo> fields;
  final String? selectedFieldId;
  final ValueChanged<String?> onChanged;

  /// Text shown for the "no mapping" entry.
  final String noneLabel;

  const FieldDropdown({
    super.key,
    required this.fields,
    required this.selectedFieldId,
    required this.onChanged,
    this.noneLabel = '(None)',
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

    // Guard: if the currently-selected id is no longer in the list (field
    // deleted on GitHub since we saved it), fall back to null so Flutter's
    // DropdownButton doesn't assert.
    final validSelection = selectedFieldId != null &&
            fields.any((f) => f.id == selectedFieldId)
        ? selectedFieldId
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        border: Border.all(color: withOpacity(outlineVariant, 0.15)),
      ),
      child: DropdownButton<String?>(
        value: validSelection,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: textStyle,
        dropdownColor: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(noneLabel, style: noneStyle),
          ),
          for (final field in fields)
            DropdownMenuItem<String?>(
              value: field.id,
              child: Text(field.name, style: textStyle),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
