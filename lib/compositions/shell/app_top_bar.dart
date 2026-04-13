import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Sticky frosted-glass app bar shown above every shell route.
///
/// Shows the app title on the left and the authenticated user's avatar +
/// username on the right, fetched via the GitHub GraphQL API.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  static const double barHeight = 64;
  static const pageKey = ValueKey('app-top-bar');

  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceBright = resolveColor(context, ColorTokens.surface.bright);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceContainerLow = resolveColor(
      context,
      ColorTokens.surface.containerLow,
    );
    final safeTop = MediaQuery.paddingOf(context).top;

    final userAsync = ref.watch(userInfoProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Box(
          key: pageKey,
          style: BoxStyler()
              .color(withOpacity(surfaceBright, 0.8))
              .height(barHeight + safeTop)
              .paddingOnly(top: safeTop, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StyledText(
                'GitHub Todos',
                style: editorialTextStyle(
                  TextTokens.title.$large,
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              userAsync.when(
                data: (viewer) {
                  if (viewer == null) return const SizedBox.shrink();

                  final displayName = viewer.name ?? viewer.login;

                  return RowBox(
                    style: editorialRowStyle(spacing: 12),
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: surfaceContainerLow,
                        backgroundImage: NetworkImage(viewer.avatarUrl),
                      ),
                      StyledText(
                        displayName,
                        style: editorialTextStyle(
                          TextTokens.label.$large,
                          color: onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
