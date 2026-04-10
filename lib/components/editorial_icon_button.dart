import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:mix/mix.dart';

enum IconButtonVariation { filled, tonal, ghost }

class EditorialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? tooltip;
  final double size;
  final IconButtonVariation variation;

  const EditorialIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.size = 48,
    this.variation = IconButtonVariation.tonal,
  });

  @override
  Widget build(BuildContext context) {
    final button = PressableBox(
      enabled: enabled && onPressed != null,
      onPress: enabled ? onPressed : null,
      style: _style(context),
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: StyledIcon(
          icon: icon,
          style: editorialIconStyle(
            color: _foregroundColor(context),
            size: size * 0.42,
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
  }

  Color _foregroundColor(BuildContext context) {
    return switch (variation) {
      IconButtonVariation.filled => resolveColor(
        context,
        ColorTokens.primary.on,
      ),
      IconButtonVariation.tonal => resolveColor(
        context,
        ColorTokens.surface.onVariant,
      ),
      IconButtonVariation.ghost => resolveColor(
        context,
        ColorTokens.surface.on,
      ),
    };
  }

  BoxStyler _style(BuildContext context) {
    final primaryContainer = resolveColor(
      context,
      ColorTokens.primary.container,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final surfaceHigh = resolveColor(
      context,
      ColorTokens.surface.containerHigh,
    );
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final shapeRadius = variation == IconButtonVariation.filled
        ? size / 2
        : editorialRadiusMedium;

    var style = BoxStyler()
        .width(size)
        .height(size)
        .alignment(Alignment.center)
        .borderRounded(shapeRadius)
        .animate(editorialAnimation)
        .onPressed(BoxStyler().scale(0.94));

    return switch (variation) {
      IconButtonVariation.filled =>
        style
            .color(primaryContainer)
            .shadow(
              editorialShadow(
                color: withOpacity(primary, 0.14),
                blurRadius: 24,
                yOffset: 10,
              ),
            ),
      IconButtonVariation.tonal =>
        style
            .color(surfaceHigh)
            .onPressed(BoxStyler().color(surfaceLow).scale(0.94)),
      IconButtonVariation.ghost =>
        style
            .color(Colors.transparent)
            .onHovered(BoxStyler().color(withOpacity(primary, 0.08)))
            .onPressed(
              BoxStyler().color(withOpacity(primary, 0.08)).scale(0.94),
            ),
    };
  }
}
