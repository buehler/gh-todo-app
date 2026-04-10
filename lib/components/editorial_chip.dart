import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

enum ChipVariation { filter, status, hash }

class EditorialChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? leadingDotColor;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ChipVariation variation;

  const EditorialChip({
    super.key,
    required this.label,
    this.selected = false,
    this.leadingDotColor,
    this.onPressed,
    this.icon,
    this.variation = ChipVariation.filter,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);
    final textToken = switch (variation) {
      ChipVariation.hash => TextTokens.label.$medium,
      ChipVariation.status => TextTokens.label.$small,
      ChipVariation.filter => TextTokens.label.$large,
    };

    final textStyle = editorialTextStyle(
      textToken,
      color: palette.foreground,
      fontWeight: variation == ChipVariation.filter
          ? FontWeight.w700
          : FontWeight.w800,
      letterSpacing: switch (variation) {
        ChipVariation.filter => -0.1,
        ChipVariation.status => 0.4,
        ChipVariation.hash => 0.2,
      },
      fontFeatures: variation == ChipVariation.hash
          ? const [FontFeature.tabularFigures()]
          : null,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          StyledIcon(
            icon: icon,
            style: editorialIconStyle(color: palette.foreground, size: 14),
          ),
          const SizedBox(width: 6),
        ],
        if (leadingDotColor != null) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: leadingDotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        StyledText(
          variation == ChipVariation.status ? label.toUpperCase() : label,
          style: textStyle,
        ),
      ],
    );

    final child = PressableBox(
      enabled: onPressed != null,
      onPress: onPressed,
      style: _style(context, palette),
      child: content,
    );

    return variation == ChipVariation.filter
        ? child
        : Opacity(opacity: onPressed == null ? 1 : 1, child: child);
  }

  _ChipPalette _palette(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final primaryFixed = resolveColor(context, ColorTokens.primary.fixed);
    final primaryOnFixedVariant = resolveColor(
      context,
      ColorTokens.primary.onFixedVariant,
    );
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onPrimary = resolveColor(context, ColorTokens.primary.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final tertiary = resolveColor(context, ColorTokens.tertiary.$default);
    final tertiaryContainer = resolveColor(
      context,
      ColorTokens.tertiary.container,
    );
    final onTertiaryContainer = resolveColor(
      context,
      ColorTokens.tertiary.onContainer,
    );
    final error = resolveColor(context, ColorTokens.error.$default);
    final errorContainer = resolveColor(context, ColorTokens.error.container);
    final onErrorContainer = resolveColor(
      context,
      ColorTokens.error.onContainer,
    );
    final secondaryContainer = resolveColor(
      context,
      ColorTokens.secondary.container,
    );
    final onSecondaryFixedVariant = resolveColor(
      context,
      ColorTokens.secondary.onFixedVariant,
    );

    return switch (variation) {
      ChipVariation.filter =>
        selected
            ? _ChipPalette(onPrimary, primary)
            : _ChipPalette(onSurfaceVariant, surfaceLowest),
      ChipVariation.hash => _ChipPalette(
        onSecondaryFixedVariant,
        secondaryContainer,
      ),
      ChipVariation.status => switch (leadingDotColor?.toARGB32()) {
        final value when value == tertiary.toARGB32() => _ChipPalette(
          onTertiaryContainer,
          tertiaryContainer,
        ),
        final value when value == error.toARGB32() => _ChipPalette(
          onErrorContainer,
          errorContainer,
        ),
        _ => _ChipPalette(primaryOnFixedVariant, primaryFixed),
      },
    };
  }

  BoxStyler _style(BuildContext context, _ChipPalette palette) {
    final primary = resolveColor(context, ColorTokens.primary.$default);

    return BoxStyler()
        .color(palette.background)
        .borderRounded(switch (variation) {
          ChipVariation.filter => 999,
          ChipVariation.status => editorialRadiusSmall,
          ChipVariation.hash => 10,
        })
        .paddingOnly(
          horizontal: switch (variation) {
            ChipVariation.filter => 18,
            ChipVariation.status => 12,
            ChipVariation.hash => 10,
          },
          vertical: switch (variation) {
            ChipVariation.filter => 10,
            ChipVariation.status => 7,
            ChipVariation.hash => 7,
          },
        )
        .animate(editorialAnimation)
        .onHovered(BoxStyler().color(withOpacity(primary, 0.06)))
        .onPressed(BoxStyler().scale(0.98));
  }
}

class _ChipPalette {
  final Color foreground;
  final Color background;

  const _ChipPalette(this.foreground, this.background);
}
