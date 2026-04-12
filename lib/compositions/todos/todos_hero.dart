import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Editorial greeting + active-issue summary shown at the top of the
/// todos feed.
class TodosHero extends StatelessWidget {
  const TodosHero({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);

    final greetingStyle = resolveTextStyle(
      context,
      TextTokens.body.$large,
    ).copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w500);

    final headlineBase = resolveTextStyle(
      context,
      TextTokens.display.$large,
    ).copyWith(
      color: onSurface,
      fontWeight: FontWeight.w800,
      fontSize: 34,
      height: 1.1,
      letterSpacing: -0.8,
    );

    final primarySpan = headlineBase.copyWith(color: primary);

    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 8,
        crossAxis: CrossAxisAlignment.start,
      ).constraints(BoxConstraintsMix.maxWidth(640)),
      children: [
        Text('Morning, Alex.', style: greetingStyle),
        Text.rich(
          TextSpan(
            style: headlineBase,
            children: [
              const TextSpan(text: 'You have '),
              TextSpan(text: '12 active issues', style: primarySpan),
              const TextSpan(text: ' across 3 core projects today.'),
            ],
          ),
        ),
      ],
    );
  }
}
