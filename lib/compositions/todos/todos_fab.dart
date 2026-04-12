import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Gradient rounded-square FAB that floats over the todos feed.
///
/// Intentionally lives in the todos composition (not the shell) so it is
/// simply absent whenever the settings branch is active.
class TodosFab extends StatelessWidget {
  static const pageKey = ValueKey('todos-fab');

  final VoidCallback? onPressed;

  const TodosFab({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final primaryContainer = resolveColor(
      context,
      ColorTokens.primary.container,
    );
    final onPrimary = resolveColor(context, ColorTokens.primary.on);

    return PressableBox(
      key: pageKey,
      onPress: onPressed,
      style: BoxStyler()
          .width(64)
          .height(64)
          .linearGradient(
            colors: [primary, primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
          .borderRounded(18)
          .alignment(Alignment.center)
          .animate(editorialAnimation)
          .shadow(
            editorialShadow(
              color: withOpacity(primary, 0.15),
              blurRadius: 32,
              yOffset: 12,
            ),
          )
          .onHovered(BoxStyler().scale(1.04))
          .onPressed(BoxStyler().scale(0.95)),
      child: StyledIcon(
        icon: LucideIcons.plus,
        style: editorialIconStyle(color: onPrimary, size: 28),
      ),
    );
  }
}
