import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Account settings card with PAT row.
class SettingsAccountSection extends StatelessWidget {
  final VoidCallback onPatPressed;
  final VoidCallback onViewLogsPressed;
  final VoidCallback onViewChangelogPressed;
  final PatAuthMetadata? metadata;
  final bool isLoading;
  final String? errorText;

  const SettingsAccountSection({
    required this.onPatPressed,
    required this.onViewLogsPressed,
    required this.onViewChangelogPressed,
    required this.metadata,
    required this.isLoading,
    required this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorialCard(
          variation: CardVariation.elevated,
          padding: EdgeInsets.zero,
          child: _AccountRow(
            icon: LucideIcons.keyRound,
            iconBgColor: withOpacity(primary, 0.1),
            iconColor: primary,
            title: 'GitHub Personal Access Token',
            subtitle: '••••••••••••••••',
            onPress: onPatPressed,
          ),
        ),
        const SizedBox(height: 12),
        EditorialCard(
          variation: CardVariation.recessed,
          padding: const EdgeInsets.all(20),
          child: ColumnBox(
            style: editorialColumnStyle(
              spacing: 10,
              crossAxis: CrossAxisAlignment.start,
            ),
            children: [
              StyledText(
                'Current PAT scopes',
                style: editorialTextStyle(
                  TextTokens.title.$medium,
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isLoading)
                StyledText(
                  'Loading cached token metadata.',
                  style: editorialTextStyle(
                    TextTokens.body.$small,
                    color: onSurfaceVariant,
                  ),
                )
              else if (errorText != null)
                StyledText(
                  errorText!,
                  style: editorialTextStyle(
                    TextTokens.body.$small,
                    color: onSurfaceVariant,
                  ),
                )
              else if (metadata == null)
                StyledText(
                  'No cached scope information is available.',
                  style: editorialTextStyle(
                    TextTokens.body.$small,
                    color: onSurfaceVariant,
                  ),
                )
              else ...[
                StyledText(
                  metadata!.hasRequiredScopes
                      ? 'Ready for ${metadata!.user.login}.'
                      : 'Required scopes are missing.',
                  style: editorialTextStyle(
                    TextTokens.body.$small,
                    color: onSurfaceVariant,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final scope in metadata!.normalizedScopes)
                      EditorialChip(label: scope),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        EditorialCard(
          variation: CardVariation.elevated,
          padding: EdgeInsets.zero,
          child: _AccountRow(
            icon: LucideIcons.scrollText,
            iconBgColor: withOpacity(primary, 0.1),
            iconColor: primary,
            title: 'View Logs',
            subtitle: 'Open local application logs.',
            onPress: onViewLogsPressed,
          ),
        ),
        const SizedBox(height: 12),
        EditorialCard(
          variation: CardVariation.elevated,
          padding: EdgeInsets.zero,
          child: _AccountRow(
            icon: LucideIcons.history,
            iconBgColor: withOpacity(primary, 0.1),
            iconColor: primary,
            title: 'View Changelog',
            subtitle: 'See what has changed in the app.',
            onPress: onViewChangelogPressed,
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const _AccountRow({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onPress,
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
      onPress: onPress,
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
