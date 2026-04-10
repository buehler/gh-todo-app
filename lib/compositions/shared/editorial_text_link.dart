import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
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
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: mainAxisSize,
        children: [
          if (leadingIcon != null) ...[
            StyledIcon(
              icon: leadingIcon,
              style: editorialIconStyle(color: primary, size: 14),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: StyledText(
              label,
              style: editorialTextStyle(
                TextTokens.label.$large,
                color: onPressed == null ? onSurfaceVariant : primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
