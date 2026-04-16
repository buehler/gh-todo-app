import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class OfflineNotice extends StatelessWidget {
  final String message;

  const OfflineNotice({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final iconColor = resolveColor(context, ColorTokens.primary.$default);
    final textColor = resolveColor(context, ColorTokens.surface.onVariant);

    return Box(
      style: BoxStyler()
          .color(surfaceLow)
          .borderRounded(editorialRadiusMedium)
          .paddingOnly(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StyledIcon(
            icon: LucideIcons.cloudOff,
            style: editorialIconStyle(color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StyledText(
              message,
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
