import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class ConnectBrandBlock extends StatelessWidget {
  const ConnectBrandBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final onBackground = resolveColor(context, ColorTokens.background.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final onPrimary = resolveColor(context, ColorTokens.primary.on);

    return ColumnBox(
      style: editorialColumnStyle(spacing: 32),
      children: [
        Box(
          style: _iconBadgeStyle(onBackground),
          child: StyledIcon(
            icon: LucideIcons.squareTerminal,
            style: editorialIconStyle(color: onPrimary, size: 28),
          ),
        ),
        ColumnBox(
          style: editorialColumnStyle(
            spacing: 16,
          ).constraints(BoxConstraintsMix.maxWidth(440)),
          children: [
            StyledText(
              'Connect to GitHub',
              style: editorialTextStyle(
                TextTokens.display.$large,
                color: onBackground,
                fontWeight: FontWeight.w800,
              ),
            ),
            StyledText(
              'Bridge your engineering workflow with a precise editorial interface. Access your repositories and issues securely.',
              style: editorialTextStyle(
                TextTokens.body.$large,
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  BoxStyler _iconBadgeStyle(Color onBackground) {
    return BoxStyler()
        .width(56)
        .height(56)
        .color(onBackground)
        .borderRounded(editorialRadiusMedium)
        .alignment(Alignment.center)
        .shadow(
          editorialShadow(
            color: withOpacity(onBackground, 0.08),
            blurRadius: 18,
            yOffset: 10,
          ),
        );
  }
}
