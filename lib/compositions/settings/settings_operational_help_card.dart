import 'package:flutter/material.dart';
import 'package:gh_todos/components/editorial_card.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class SettingsOperationalHelpCard extends StatelessWidget {
  const SettingsOperationalHelpCard({super.key});

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
                icon: LucideIcons.folderGit2,
                style: editorialIconStyle(color: primary, size: 18),
              ),
              Expanded(
                child: StyledText(
                  'Project setup requirements',
                  style: editorialTextStyle(
                    TextTokens.title.$medium,
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          StyledText(
            'You need two GitHub resources: a repository where issues live, and a GitHub Project with that repository attached.',
            style: editorialTextStyle(
              TextTokens.body.$small,
              color: onSurfaceVariant,
            ),
          ),
          StyledText(
            'The simplest path is to create the repository first, then create the project inside that repository.',
            style: editorialTextStyle(
              TextTokens.body.$small,
              color: onSurfaceVariant,
            ),
          ),
          StyledText(
            'In GitHub Project settings, set the default repository. That is the link this app relies on for quick-add.',
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
