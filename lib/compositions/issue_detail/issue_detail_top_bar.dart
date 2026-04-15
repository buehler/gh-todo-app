import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Frosted top bar for the issue detail page.
///
/// Mirrors the `AppTopBar` recipe (blur + translucent surface + safe-area
/// padding), but with a back chevron on the leading edge, "Issue Details"
/// title, and a trailing kebab menu button. No avatar.
class IssueDetailTopBar extends StatelessWidget {
  static const double barHeight = 64;
  static const pageKey = ValueKey('issue-detail-top-bar');
  static const backButtonKey = ValueKey('issue-detail-top-bar-back');
  static const menuButtonKey = ValueKey('issue-detail-top-bar-menu');

  final VoidCallback onBack;
  final VoidCallback? onMenuPressed;

  const IssueDetailTopBar({
    required this.onBack,
    this.onMenuPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBright = resolveColor(context, ColorTokens.surface.bright);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final safeTop = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Box(
          key: pageKey,
          style: BoxStyler()
              .color(withOpacity(surfaceBright, 0.8))
              .height(barHeight + safeTop)
              .paddingOnly(top: safeTop, horizontal: 12),
          child: Row(
            children: [
              IconButton(
                key: backButtonKey,
                onPressed: onBack,
                icon: Icon(LucideIcons.arrowLeft, color: onSurfaceVariant),
                splashRadius: 22,
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: StyledText(
                  'Issue Details',
                  style: editorialTextStyle(
                    TextTokens.title.$large,
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              IconButton(
                key: menuButtonKey,
                onPressed: onMenuPressed,
                icon: Icon(LucideIcons.ellipsis, color: onSurfaceVariant),
                splashRadius: 22,
                tooltip: 'More actions',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
