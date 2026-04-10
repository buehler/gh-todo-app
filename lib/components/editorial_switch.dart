import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

enum SwitchVariation { editorial }

class EditorialSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final SwitchVariation variation;

  const EditorialSwitch({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.variation = SwitchVariation.editorial,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final secondaryFixedDim = resolveColor(
      context,
      ColorTokens.secondary.fixedDim,
    );

    return Semantics(
      enabled: enabled,
      toggled: value,
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: PressableBox(
          enabled: enabled && onChanged != null,
          onPress: onChanged == null ? null : () => onChanged!(!value),
          style: BoxStyler()
              .color(surfaceLowest)
              .borderRounded(editorialRadiusMedium)
              .paddingOnly(horizontal: 14, vertical: 12)
              .animate(editorialAnimation)
              .onPressed(BoxStyler().scale(0.99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledText(
                label,
                style: editorialTextStyle(
                  TextTokens.body.$small,
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Box(
                style: BoxStyler()
                    .width(48)
                    .height(28)
                    .color(value ? primary : secondaryFixedDim)
                    .borderRounded(999)
                    .paddingAll(4),
                child: AnimatedAlign(
                  duration: editorialInteractionDuration,
                  curve: Curves.easeOutCubic,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Box(
                    style: BoxStyler()
                        .width(20)
                        .height(20)
                        .color(Colors.white)
                        .borderRounded(999)
                        .shadow(
                          editorialShadow(
                            color: withOpacity(
                              resolveColor(context, ColorTokens.surface.on),
                              0.08,
                            ),
                            blurRadius: 8,
                            yOffset: 2,
                          ),
                        ),
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
