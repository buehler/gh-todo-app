import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Editorial greeting + active-issue summary shown at the top of the
/// todos feed.
///
/// The greeting line is personalized via the GitHub GraphQL `viewer` query.
/// Falls back to "Hi there." while loading or on error.
class TodosHero extends ConsumerWidget {
  const TodosHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final userAsync = ref.watch(userInfoProvider);

    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 8,
        crossAxis: CrossAxisAlignment.start,
      ).constraints(BoxConstraintsMix.maxWidth(640)),
      children: [
        userAsync.when(
          data: (viewer) {
            final name = viewer?.name ?? viewer?.login;
            final greeting = name != null ? 'Hi, $name.' : 'Hi there.';
            return Text(greeting, style: greetingStyle);
          },
          loading: () => Text('Hi there.', style: greetingStyle),
          error: (_, __) => Text('Hi there.', style: greetingStyle),
        ),
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
