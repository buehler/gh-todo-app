import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:mix/mix.dart';

enum CardVariation { elevated, recessed, accent }

class EditorialCard extends StatelessWidget {
  static const accentStripKey = ValueKey('editorial-card-accent-strip');

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool enabled;
  final CardVariation variation;

  const EditorialCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.accentColor,
    this.enabled = true,
    this.variation = CardVariation.elevated,
  });

  @override
  Widget build(BuildContext context) {
    final content = switch (variation) {
      CardVariation.accent => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Box(
              key: accentStripKey,
              style: BoxStyler()
                  .width(6)
                  .color(
                    accentColor ??
                        resolveColor(context, ColorTokens.tertiary.$default),
                  ),
            ),
            Expanded(
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
      _ => Padding(padding: padding, child: child),
    };

    final style = _style(context);

    // When the card is not tappable, wrapping in a PressableBox would install
    // a GestureDetector with HitTestBehavior.opaque that swallows every tap
    // inside the card, blocking interaction with nested widgets (text fields,
    // links). Use a plain Box in that case so taps reach the children.
    final Widget surface = onTap == null
        ? Box(style: style, child: content)
        : PressableBox(
            enabled: enabled,
            onPress: enabled ? onTap : null,
            style: style,
            child: content,
          );

    return Opacity(opacity: enabled ? 1 : 0.58, child: surface);
  }

  BoxStyler _style(BuildContext context) {
    final low = resolveColor(context, ColorTokens.surface.containerLow);
    final lowest = resolveColor(context, ColorTokens.surface.containerLowest);
    final highest = resolveColor(context, ColorTokens.surface.containerHighest);
    final outline = resolveColor(context, ColorTokens.outline.variant);
    final shadowColor = resolveColor(context, ColorTokens.surface.on);

    var style = BoxStyler()
        .clipBehavior(Clip.antiAlias)
        .borderRounded(editorialRadiusLarge)
        .animate(editorialAnimation)
        .onPressed(BoxStyler().color(highest))
        .borderAll(color: withOpacity(outline, 0.1), width: 1);

    return switch (variation) {
      CardVariation.elevated =>
        style
            .color(lowest)
            .shadow(
              editorialShadow(
                color: withOpacity(shadowColor, 0.03),
                blurRadius: 32,
                yOffset: 12,
              ),
            ),
      CardVariation.recessed => style.color(low),
      CardVariation.accent =>
        style
            .color(lowest)
            .shadow(
              editorialShadow(
                color: withOpacity(shadowColor, 0.03),
                blurRadius: 28,
                yOffset: 10,
              ),
            ),
    };
  }
}
