import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Bottom navigation bar shared across the authenticated shell.
///
/// Two tabs: Todos (index 0) and Settings (index 1). Uses a frosted-glass
/// treatment to stay in the "Engineering Editorial" visual language.
class AppBottomNav extends StatelessWidget {
  static const double barHeight = 72;
  static const pageKey = ValueKey('app-bottom-nav');
  static const todosTabKey = ValueKey('app-bottom-nav-todos');
  static const settingsTabKey = ValueKey('app-bottom-nav-settings');

  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBright = resolveColor(context, ColorTokens.surface.bright);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Box(
          key: pageKey,
          style: BoxStyler()
              .color(withOpacity(surfaceBright, 0.8))
              .paddingOnly(
                top: 10,
                bottom: 10 + bottomInset,
                horizontal: 24,
              ),
          child: RowBox(
            style: editorialRowStyle(
              spacing: 16,
              mainAxis: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
            ),
            children: [
              _NavTab(
                key: todosTabKey,
                icon: LucideIcons.listTodo,
                label: 'TODOS',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavTab(
                key: settingsTabKey,
                icon: LucideIcons.settings,
                label: 'SETTINGS',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
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
    final outline = resolveColor(context, ColorTokens.outline.$default);
    final foreground = selected ? primaryContainer : outline;

    return PressableBox(
      onPress: onTap,
      style: BoxStyler()
          .color(selected ? surfaceContainerLow : Colors.transparent)
          .borderRounded(editorialRadiusMedium)
          .paddingOnly(horizontal: 22, vertical: 8)
          .animate(editorialAnimation)
          .onPressed(BoxStyler().scale(0.94)),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 4,
          crossAxis: CrossAxisAlignment.center,
        ),
        children: [
          StyledIcon(
            icon: icon,
            style: editorialIconStyle(color: foreground, size: 22),
          ),
          StyledText(
            label,
            style: editorialTextStyle(
              TextTokens.label.$small,
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
