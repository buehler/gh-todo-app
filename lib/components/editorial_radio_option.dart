import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

enum RadioOptionVariation { editorial }

class EditorialRadioOption<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final String label;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final RadioOptionVariation variation;

  const EditorialRadioOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    this.onChanged,
    this.enabled = true,
    this.variation = RadioOptionVariation.editorial,
  });

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final outline = resolveColor(context, ColorTokens.outline.variant);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );

    return Semantics(
      checked: _selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: PressableBox(
          enabled: enabled && onChanged != null,
          onPress: onChanged == null ? null : () => onChanged!(value),
          style: BoxStyler()
              .paddingOnly(horizontal: 2, vertical: 2)
              .borderRounded(editorialRadiusSmall)
              .animate(editorialAnimation)
              .onHovered(BoxStyler().color(withOpacity(primary, 0.04)))
              .onPressed(BoxStyler().scale(0.98)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Box(
                style: BoxStyler()
                    .width(20)
                    .height(20)
                    .color(surfaceLowest)
                    .borderRounded(999)
                    .borderAll(
                      color: _selected ? primary : outline,
                      width: _selected ? 2 : 1.5,
                    )
                    .alignment(Alignment.center),
                child: _selected
                    ? Box(
                        style: BoxStyler()
                            .width(8)
                            .height(8)
                            .color(primary)
                            .borderRounded(999),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              StyledText(
                label,
                style: editorialTextStyle(
                  TextTokens.body.$small,
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
