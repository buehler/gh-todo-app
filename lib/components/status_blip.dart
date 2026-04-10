import 'package:flutter/widgets.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:mix/mix.dart';

enum StatusBlipVariation { active, alert, neutral }

class StatusBlip extends StatelessWidget {
  final StatusBlipVariation variation;
  final double size;

  const StatusBlip({
    super.key,
    this.variation = StatusBlipVariation.active,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (variation) {
      StatusBlipVariation.active => resolveColor(
        context,
        ColorTokens.primary.$default,
      ),
      StatusBlipVariation.alert => resolveColor(
        context,
        ColorTokens.tertiary.container,
      ),
      StatusBlipVariation.neutral => resolveColor(
        context,
        ColorTokens.secondary.fixedDim,
      ),
    };

    return Box(
      style: BoxStyler()
          .width(size)
          .height(size)
          .color(color)
          .borderRounded(size)
          .shadow(
            editorialShadow(
              color: withOpacity(color, 0.3),
              blurRadius: size * 2.4,
              yOffset: 0,
              spreadRadius: size * 0.5,
            ),
          ),
    );
  }
}
