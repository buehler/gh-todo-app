import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/services/mock_todos_data.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Account settings card with PAT and sync frequency rows.
class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    return EditorialCard(
      variation: CardVariation.elevated,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AccountRow(
            icon: LucideIcons.keyRound,
            iconBgColor: withOpacity(
              resolveColor(context, ColorTokens.primary.$default),
              0.1,
            ),
            iconColor: resolveColor(context, ColorTokens.primary.$default),
            title: 'GitHub Personal Access Token',
            subtitle: mockMaskedPat,
          ),
          Box(
            style: BoxStyler()
                .height(1)
                .color(withOpacity(outlineVariant, 0.15))
                .margin(EdgeInsetsMix.symmetric(horizontal: 20)),
          ),
          _AccountRow(
            icon: LucideIcons.refreshCw,
            iconBgColor: withOpacity(
              resolveColor(context, ColorTokens.tertiary.$default),
              0.1,
            ),
            iconColor: resolveColor(context, ColorTokens.tertiary.$default),
            title: 'Sync Frequency',
            subtitle: mockSyncFrequency,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _AccountRow({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );
    final outline = resolveColor(context, ColorTokens.outline.$default);

    return PressableBox(
      onPress: () {},
      style: BoxStyler()
          .color(Colors.transparent)
          .paddingOnly(horizontal: 20, vertical: 16)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(surfaceHighest)),
      child: RowBox(
        style: editorialRowStyle(spacing: 16, mainAxisSize: MainAxisSize.max),
        children: [
          Box(
            style: BoxStyler()
                .width(40)
                .height(40)
                .color(iconBgColor)
                .borderRounded(editorialRadiusSmall)
                .alignment(Alignment.center),
            child: StyledIcon(
              icon: icon,
              style: editorialIconStyle(color: iconColor, size: 20),
            ),
          ),
          Expanded(
            child: ColumnBox(
              style: editorialColumnStyle(
                spacing: 2,
                crossAxis: CrossAxisAlignment.start,
              ),
              children: [
                StyledText(
                  title,
                  style: editorialTextStyle(
                    TextTokens.body.$medium,
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                StyledText(
                  subtitle,
                  style: editorialTextStyle(
                    TextTokens.body.$small,
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StyledIcon(
            icon: LucideIcons.chevronRight,
            style: editorialIconStyle(color: outline, size: 20),
          ),
        ],
      ),
    );
  }
}
