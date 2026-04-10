import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:mix/mix.dart';

class EditorialTextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final MainAxisSize mainAxisSize;

  const EditorialTextLink({
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.mainAxisSize = MainAxisSize.min,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final isEnabled = onPressed != null;

    return PressableBox(
      enabled: isEnabled,
      onPress: onPressed,
      style: editorialTextLinkStyle(context, enabled: isEnabled),
      child: RowBox(
        style: editorialTextLinkRowStyle(mainAxisSize: mainAxisSize),
        children: [
          if (leadingIcon != null) ...[
            StyledIcon(
              icon: leadingIcon,
              style: editorialIconStyle(color: primary, size: 14),
            ),
          ],
          Flexible(
            child: StyledText(
              label,
              style: editorialTextLinkTextStyle(context, enabled: isEnabled),
            ),
          ),
        ],
      ),
    );
  }
}
