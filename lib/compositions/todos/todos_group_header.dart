import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/services/mock_todos_data.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// The "Design System / 4 OPEN" style group header.
///
/// Renders an accent strip, the group title and a right-aligned open count.
class TodosGroupHeader extends StatelessWidget {
  final TodoGroup group;

  const TodosGroupHeader({required this.group, super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final outline = resolveColor(context, ColorTokens.outline.$default);
    final accent = switch (group.accent) {
      GroupAccent.tertiary => resolveColor(
        context,
        ColorTokens.tertiary.$default,
      ),
      GroupAccent.primary => resolveColor(
        context,
        ColorTokens.primary.$default,
      ),
    };

    return RowBox(
      style: editorialRowStyle(
        spacing: 12,
        mainAxis: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
      ),
      children: [
        RowBox(
          style: editorialRowStyle(spacing: 12),
          children: [
            Box(
              style: BoxStyler()
                  .width(4)
                  .height(24)
                  .color(accent)
                  .borderRounded(999),
            ),
            StyledText(
              group.name,
              style: editorialTextStyle(
                TextTokens.title.$large,
                color: onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        StyledText(
          '${group.openCount} OPEN',
          style: editorialTextStyle(
            TextTokens.label.$small,
            color: outline,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
