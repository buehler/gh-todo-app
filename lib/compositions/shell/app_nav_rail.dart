import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Frosted-glass vertical navigation rail for wide layouts (tablet landscape,
/// desktop, web ≥ 900px).
///
/// Replaces [AppBottomNav] on wide widths. Carries the same two tabs plus the
/// authenticated user's avatar + name at the bottom — when the rail is
/// visible, [AppTopBar] hides its avatar block so the identity surfaces here.
class AppNavRail extends ConsumerWidget {
  static const double railWidth = 224;
  static const pageKey = ValueKey('app-nav-rail');
  static const todosTabKey = ValueKey('app-nav-rail-todos');
  static const settingsTabKey = ValueKey('app-nav-rail-settings');

  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavRail({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceBright = resolveColor(context, ColorTokens.surface.bright);
    final surfaceContainerLow = resolveColor(
      context,
      ColorTokens.surface.containerLow,
    );
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final userAsync = ref.watch(userInfoProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Box(
          key: pageKey,
          style: BoxStyler()
              .color(withOpacity(surfaceBright, 0.8))
              .width(railWidth)
              .paddingOnly(
                top: topInset + 24,
                bottom: 20 + bottomInset,
                left: 20,
                right: 20,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wordmark — sits above tabs at rail-top so the top-bar can
              // elide its own title on wide screens if desired later. Kept
              // here for now so the rail reads as a standalone navigation
              // surface.
              StyledText(
                'GitHub Todos',
                style: editorialTextStyle(
                  TextTokens.title.$small,
                  color: resolveColor(context, ColorTokens.surface.on),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),
              _NavRailTab(
                key: todosTabKey,
                icon: LucideIcons.listTodo,
                label: 'Todos',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              const SizedBox(height: 8),
              _NavRailTab(
                key: settingsTabKey,
                icon: LucideIcons.settings,
                label: 'Settings',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              const Spacer(),
              // Identity block: avatar + name at the rail's foot.
              userAsync.when(
                data: (viewer) {
                  if (viewer == null) return const SizedBox.shrink();
                  final displayName = viewer.name ?? viewer.login;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: surfaceContainerLow,
                        backgroundImage: NetworkImage(viewer.avatarUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StyledText(
                          displayName,
                          style: editorialTextStyle(
                            TextTokens.label.$large,
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
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

class _NavRailTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavRailTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primaryContainer = resolveColor(
      context,
      ColorTokens.primary.container,
    );
    final surfaceContainerLow = resolveColor(
      context,
      ColorTokens.surface.containerLow,
    );
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final foreground = selected ? primaryContainer : onSurfaceVariant;

    return PressableBox(
      onPress: onTap,
      style: BoxStyler()
          .color(selected ? surfaceContainerLow : Colors.transparent)
          .borderRounded(editorialRadiusMedium)
          .paddingOnly(horizontal: 14, vertical: 12)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(withOpacity(surfaceContainerLow, 0.6)))
          .onPressed(BoxStyler().scale(0.98)),
      child: Row(
        children: [
          StyledIcon(
            icon: icon,
            style: editorialIconStyle(color: foreground, size: 20),
          ),
          const SizedBox(width: 14),
          StyledText(
            label,
            style: editorialTextStyle(
              TextTokens.label.$large,
              color: foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
