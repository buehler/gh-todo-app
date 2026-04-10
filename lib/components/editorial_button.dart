import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

enum ButtonVariation { primary, secondary, tertiary }

class EditorialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool enabled;
  final bool loading;
  final ButtonVariation variation;

  const EditorialButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.enabled = true,
    this.loading = false,
    this.variation = ButtonVariation.primary,
  });

  bool get _isInteractive => enabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundColor(context);
    final content = Opacity(
      opacity: enabled ? 1 : 0.56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            ),
          if (!loading && leadingIcon != null) ...[
            StyledIcon(
              icon: leadingIcon,
              style: editorialIconStyle(color: foreground, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          StyledText(
            label,
            style: editorialTextStyle(
              TextTokens.title.$small,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!loading && trailingIcon != null) ...[
            const SizedBox(width: 10),
            StyledIcon(
              icon: trailingIcon,
              style: editorialIconStyle(color: foreground, size: 18),
            ),
          ],
        ],
      ),
    );

    return PressableBox(
      enabled: _isInteractive,
      onPress: _isInteractive ? onPressed : null,
      style: _style(context),
      child: content,
    );
  }

  Color _foregroundColor(BuildContext context) {
    return switch (variation) {
      ButtonVariation.primary => resolveColor(context, ColorTokens.primary.on),
      ButtonVariation.secondary => resolveColor(
        context,
        ColorTokens.surface.onVariant,
      ),
      ButtonVariation.tertiary => resolveColor(
        context,
        ColorTokens.primary.onFixedVariant,
      ),
    };
  }

  BoxStyler _style(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final primaryContainer = resolveColor(
      context,
      ColorTokens.primary.container,
    );
    final surfaceHigh = resolveColor(
      context,
      ColorTokens.surface.containerHigh,
    );
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );
    final ghostTint = withOpacity(primary, 0.08);

    var style = BoxStyler()
        .minHeight(48)
        .paddingOnly(
          horizontal: variation == ButtonVariation.tertiary ? 24 : 20,
          vertical: 14,
        )
        .borderRounded(editorialRadiusMedium)
        .alignment(Alignment.center)
        .animate(editorialAnimation)
        .onPressed(
          BoxStyler()
              .scale(0.98)
              .shadow(
                editorialShadow(
                  color: withOpacity(primary, 0.08),
                  blurRadius: 18,
                  yOffset: 8,
                ),
              ),
        );

    style = switch (variation) {
      ButtonVariation.primary =>
        style
            .linearGradient(
              colors: [primary, primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            .shadow(
              editorialShadow(
                color: withOpacity(primary, 0.15),
                blurRadius: 32,
                yOffset: 12,
              ),
            ),
      ButtonVariation.secondary =>
        style
            .color(surfaceHigh)
            .onPressed(BoxStyler().color(surfaceHighest).scale(0.98)),
      ButtonVariation.tertiary =>
        style
            .color(Colors.transparent)
            .onHovered(BoxStyler().color(ghostTint))
            .onPressed(BoxStyler().color(ghostTint).scale(0.98)),
    };

    if (!enabled) {
      style = style.onDisabled(
        BoxStyler().shadow(
          editorialShadow(color: Colors.transparent, blurRadius: 0, yOffset: 0),
        ),
      );
    }

    return style;
  }
}
