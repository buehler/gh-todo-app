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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Box(
          style: BoxStyler()
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
              ),
          child: StyledIcon(
            icon: LucideIcons.squareTerminal,
            style: editorialIconStyle(color: onPrimary, size: 28),
          ),
        ),
        const SizedBox(height: 32),
        StyledText(
          'Connect to GitHub',
          style: editorialTextStyle(
            TextTokens.display.$large,
            color: onBackground,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: StyledText(
            'Bridge your engineering workflow with a precise editorial interface. Access your repositories and issues securely.',
            style: editorialTextStyle(
              TextTokens.body.$large,
              color: onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
