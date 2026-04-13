import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';

/// Editorial greeting shown at the top of the todos feed.
///
/// The greeting line is personalized via the GitHub GraphQL `viewer` query.
/// Falls back to "Hi there." while loading or on error.
class TodosHero extends ConsumerWidget {
  const TodosHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    final greetingStyle = resolveTextStyle(
      context,
      TextTokens.body.$large,
    ).copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w500);

    final userAsync = ref.watch(userInfoProvider);

    return userAsync.when(
      data: (viewer) {
        final name = viewer?.name ?? viewer?.login;
        final greeting = name != null ? 'Hi, $name.' : 'Hi there.';
        return Text(greeting, style: greetingStyle);
      },
      loading: () => Text('Hi there.', style: greetingStyle),
      error: (_, _) => Text('Hi there.', style: greetingStyle),
    );
  }
}
