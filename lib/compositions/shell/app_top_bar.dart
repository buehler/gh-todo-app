import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/auth_metadata_provider.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Sticky frosted-glass app bar shown above shell routes on compact/medium
/// widths (phones, tablet portrait).
///
/// On wide widths (≥ 900) the shell hides this bar entirely — the nav rail
/// owns branding + identity. Pages size their top padding through
/// [AppTopBar.effectiveHeight] so they collapse the reserved space on wide.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  static const double barHeight = 64;
  static const pageKey = ValueKey('app-top-bar');

  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  /// Height pages should reserve at the top for the shell's top bar.
  ///
  /// Zero on wide layouts (tablet landscape / desktop) because the shell
  /// hides the bar entirely — the nav rail owns branding + identity and
  /// each pane handles its own top chrome. Callers combine this with
  /// `MediaQuery.paddingOf(context).top` for their final top padding.
  static double effectiveHeight(BuildContext context) {
    return isWide(context) ? 0 : barHeight;
  }

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

    final metadataAsync = ref.watch(authMetadataProvider);

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
              metadataAsync.when(
                data: (metadata) {
                  if (metadata == null) return const SizedBox.shrink();

                  final displayName = metadata.user.name ?? metadata.user.login;

                  return RowBox(
                    style: editorialRowStyle(spacing: 12),
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: surfaceContainerLow,
                        backgroundImage: NetworkImage(metadata.user.avatarUrl),
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
