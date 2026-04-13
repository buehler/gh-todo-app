import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/settings_project_item.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Saved projects list + "Add Project" button.
class SettingsProjectsSection extends StatelessWidget {
  final List<Project> projects;
  final VoidCallback onAddPressed;
  final ValueChanged<Project> onProjectTapped;

  const SettingsProjectsSection({
    required this.projects,
    required this.onAddPressed,
    required this.onProjectTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (projects.isNotEmpty)
          EditorialCard(
            variation: CardVariation.elevated,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < projects.length; i++) ...[
                  SettingsProjectItem(
                    project: projects[i],
                    onTap: () => onProjectTapped(projects[i]),
                  ),
                  if (i < projects.length - 1)
                    Box(
                      style: BoxStyler()
                          .height(1)
                          .color(withOpacity(outlineVariant, 0.15))
                          .margin(EdgeInsetsMix.symmetric(horizontal: 20)),
                    ),
                ],
              ],
            ),
          ),
        if (projects.isNotEmpty) const SizedBox(height: 16),
        EditorialButton(
          label: 'Add Project',
          leadingIcon: LucideIcons.plus,
          variation: ButtonVariation.secondary,
          onPressed: onAddPressed,
        ),
      ],
    );
  }
}
