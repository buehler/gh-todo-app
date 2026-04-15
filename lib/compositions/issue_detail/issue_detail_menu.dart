import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Available actions behind the issue detail page's kebab menu.
enum IssueDetailMenuAction { editIssue, openInBrowser }

/// Opens the issue detail page's overflow menu as a bottom sheet and returns
/// the selected action (or `null` if dismissed). Matches the sheet-pattern used
/// elsewhere in the app (see `pat_management_sheet.dart`).
Future<IssueDetailMenuAction?> showIssueDetailMenuSheet(BuildContext context) {
  return showModalBottomSheet<IssueDetailMenuAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _IssueDetailMenuSheet(),
  );
}

class _IssueDetailMenuSheet extends StatelessWidget {
  const _IssueDetailMenuSheet();

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );

    return Container(
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: withOpacity(outlineVariant, 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _ActionRow(
            key: const ValueKey('issue-detail-menu-edit'),
            icon: LucideIcons.pencil,
            iconColor: primary,
            iconBgColor: withOpacity(primary, 0.1),
            label: 'Edit Issue',
            labelColor: onSurface,
            hoverColor: surfaceHighest,
            onTap: () =>
                Navigator.pop(context, IssueDetailMenuAction.editIssue),
          ),
          _ActionRow(
            key: const ValueKey('issue-detail-menu-open-in-browser'),
            icon: LucideIcons.externalLink,
            iconColor: primary,
            iconBgColor: withOpacity(primary, 0.1),
            label: 'Open in Browser',
            labelColor: onSurface,
            hoverColor: surfaceHighest,
            onTap: () =>
                Navigator.pop(context, IssueDetailMenuAction.openInBrowser),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final Color labelColor;
  final Color hoverColor;
  final VoidCallback onTap;

  const _ActionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.labelColor,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableBox(
      onPress: onTap,
      style: BoxStyler()
          .color(Colors.transparent)
          .paddingOnly(horizontal: 24, vertical: 14)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(hoverColor)),
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
            child: StyledText(
              label,
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
