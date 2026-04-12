import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/services/mock_todos_data.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// A single project row with accent strip, title/subtitle, toggle, and
/// optional "Mapped to" metadata.
class SettingsProjectItem extends StatelessWidget {
  final MockSettingsProject project;

  const SettingsProjectItem({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 12,
          crossAxis: CrossAxisAlignment.start,
        ),
        children: [
          _ProjectHeader(project: project),
          if (project.mappedTo.isNotEmpty)
            _MappingRow(mappedTo: project.mappedTo),
        ],
      ),
    );

    if (!project.enabled) {
      return Opacity(opacity: 0.6, child: content);
    }

    return content;
  }
}

class _ProjectHeader extends StatelessWidget {
  final MockSettingsProject project;

  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);
    final accentColor = project.enabled
        ? switch (project.accent) {
            GroupAccent.primary => resolveColor(
              context,
              ColorTokens.primary.$default,
            ),
            GroupAccent.tertiary => resolveColor(
              context,
              ColorTokens.tertiary.$default,
            ),
          }
        : outlineVariant;

    final subtitleParts = <String>[
      project.branchLabel,
      '${project.activeIssueCount} active issues',
    ];

    return RowBox(
      style: editorialRowStyle(
        spacing: 16,
        mainAxisSize: MainAxisSize.max,
        crossAxis: CrossAxisAlignment.center,
      ),
      children: [
        Box(
          style: BoxStyler()
              .width(4)
              .height(32)
              .color(accentColor)
              .borderRounded(999),
        ),
        Expanded(
          child: ColumnBox(
            style: editorialColumnStyle(
              spacing: 2,
              crossAxis: CrossAxisAlignment.start,
            ),
            children: [
              StyledText(
                project.name,
                style: editorialTextStyle(
                  TextTokens.body.$medium,
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              StyledText(
                subtitleParts.join(' • '),
                style: editorialTextStyle(
                  TextTokens.body.$small,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        EditorialSwitch(
          label: '',
          value: project.enabled,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class _MappingRow extends StatelessWidget {
  final String mappedTo;

  const _MappingRow({required this.mappedTo});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final surfaceContainer = resolveColor(
      context,
      ColorTokens.surface.$default,
    );

    final labelBase = resolveTextStyle(
      context,
      TextTokens.label.$small,
    ).copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w500);

    final labelPrimary = labelBase.copyWith(color: primary);

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: withOpacity(surfaceContainer, 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            StyledIcon(
              icon: LucideIcons.calendar,
              style: editorialIconStyle(color: onSurfaceVariant, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: labelBase,
                  children: [
                    const TextSpan(text: 'Mapped to: '),
                    TextSpan(text: mappedTo, style: labelPrimary),
                  ],
                ),
              ),
            ),
            PressableBox(
              onPress: () {},
              style: BoxStyler()
                  .color(Colors.transparent)
                  .borderRounded(6)
                  .paddingOnly(horizontal: 8, vertical: 4)
                  .animate(editorialAnimation)
                  .onHovered(
                    BoxStyler().color(withOpacity(primary, 0.05)),
                  ),
              child: StyledText(
                'MAP',
                style: editorialTextStyle(
                  TextTokens.label.$small,
                  color: primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
