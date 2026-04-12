import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// A single saved project row: project name + trailing edit icon button.
class SettingsProjectItem extends StatelessWidget {
  final Project project;

  const SettingsProjectItem({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: RowBox(
        style: editorialRowStyle(
          spacing: 12,
          mainAxisSize: MainAxisSize.max,
        ),
        children: [
          Expanded(
            child: StyledText(
              project.name,
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          EditorialIconButton(
            icon: LucideIcons.pencil,
            variation: IconButtonVariation.ghost,
            size: 36,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
