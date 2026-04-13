import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// A single saved project row: tappable, shows project name + owner subtitle.
class SettingsProjectItem extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const SettingsProjectItem({
    required this.project,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );

    return PressableBox(
      onPress: onTap,
      style: BoxStyler()
          .color(Colors.transparent)
          .paddingOnly(horizontal: 20, vertical: 16)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(surfaceHighest)),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 2,
          crossAxis: CrossAxisAlignment.start,
        ).width(double.infinity),
        children: [
          StyledText(
            project.name,
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (project.ownerLogin.isNotEmpty)
            StyledText(
              project.ownerLogin,
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
