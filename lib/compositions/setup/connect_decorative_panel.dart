import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class ConnectDecorativePanel extends StatelessWidget {
  const ConnectDecorativePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final secondary = resolveColor(context, ColorTokens.secondary.$default);
    final secondaryContainer = resolveColor(
      context,
      ColorTokens.secondary.container,
    );
    final primaryFixed = resolveColor(context, ColorTokens.primary.fixed);
    final tertiaryFixed = resolveColor(context, ColorTokens.tertiary.fixedDim);
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final tertiaryText = resolveColor(
      context,
      ColorTokens.tertiary.onFixedVariant,
    );

    return Transform.rotate(
      angle: 0.16,
      child: Box(
        style: BoxStyler()
            .width(320)
            .height(320)
            .color(withOpacity(surfaceLowest, 0.72))
            .borderRounded(48)
            .shadow(
              editorialShadow(
                color: withOpacity(onSurface, 0.08),
                blurRadius: 40,
                yOffset: 18,
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Box(
                    style: BoxStyler()
                        .width(40)
                        .height(40)
                        .color(secondaryContainer)
                        .borderRounded(999)
                        .alignment(Alignment.center),
                    child: StyledIcon(
                      icon: LucideIcons.gitCommitHorizontal,
                      style: editorialIconStyle(color: secondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DecorativeLine(widthFactor: 1),
                        SizedBox(height: 8),
                        _DecorativeLine(widthFactor: 0.64),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _DecorativeLine(widthFactor: 1, color: primaryFixed),
              const SizedBox(height: 12),
              _DecorativeLine(widthFactor: 0.74, color: primaryFixed),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: EditorialChip(
                  label: 'Merge Ready',
                  variation: ChipVariation.status,
                  leadingDotColor: tertiaryFixed,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: StyledText(
                  'Quietly staged.',
                  style: editorialTextStyle(
                    TextTokens.label.$medium,
                    color: tertiaryText,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorativeLine extends StatelessWidget {
  final double widthFactor;
  final Color? color;

  const _DecorativeLine({required this.widthFactor, this.color});

  @override
  Widget build(BuildContext context) {
    final lineColor =
        color ?? resolveColor(context, ColorTokens.outline.variant);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Box(
        style: BoxStyler()
            .height(12)
            .color(withOpacity(lineColor, 0.22))
            .borderRounded(999),
      ),
    );
  }
}
