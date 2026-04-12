import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Sticky frosted-glass app bar shown above every shell route.
///
/// Intentionally minimal per the product spec: only the app name — no avatar,
/// no filter action.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  static const double barHeight = 64;
  static const pageKey = ValueKey('app-top-bar');

  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    final surfaceBright = resolveColor(context, ColorTokens.surface.bright);
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Box(
          key: pageKey,
          style: BoxStyler()
              .color(withOpacity(surfaceBright, 0.8))
              .height(barHeight + MediaQuery.paddingOf(context).top)
              .paddingOnly(
                top: MediaQuery.paddingOf(context).top,
                horizontal: 24,
              )
              .alignment(Alignment.centerLeft),
          child: StyledText(
            'GitHub Todos',
            style: editorialTextStyle(
              TextTokens.title.$large,
              color: onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ),
    );
  }
}
