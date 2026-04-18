import 'package:flutter/material.dart';
import 'package:gh_todos/components/editorial_card.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class PatScopeHelpCard extends StatelessWidget {
  const PatScopeHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return EditorialCard(
      variation: CardVariation.recessed,
      padding: const EdgeInsets.all(20),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 12,
          crossAxis: CrossAxisAlignment.start,
        ),
        children: [
          RowBox(
            style: editorialRowStyle(spacing: 10),
            children: [
              StyledIcon(
                icon: LucideIcons.badgeInfo,
                style: editorialIconStyle(color: primary, size: 18),
              ),
              Expanded(
                child: StyledText(
                  'Personal Access Token requirements',
                  style: editorialTextStyle(
                    TextTokens.title.$medium,
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          _ScopeLine(
            label: 'Required: project',
            description:
                'Needed to read Projects and attach newly created issues to project items.',
          ),
          _ScopeLine(
            label: 'Required: repo',
            description:
                'Needed to read repositories and create or update issues.',
          ),
          _ScopeLine(
            label: 'Required: read:org',
            description:
                'Needed to load organization membership, repositories, and projects alongside personal ones.',
          ),
          StyledText(
            'Use a classic PAT. It is simpler to configure for this app than the fine-grained variant.',
            style: editorialTextStyle(
              TextTokens.body.$small,
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeLine extends StatelessWidget {
  final String label;
  final String description;

  const _ScopeLine({required this.label, required this.description});

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
          label,
          style: editorialTextStyle(
            TextTokens.body.$medium,
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        StyledText(
          description,
          style: editorialTextStyle(
            TextTokens.body.$small,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
