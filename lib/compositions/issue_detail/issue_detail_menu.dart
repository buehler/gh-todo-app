import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Available actions behind the issue detail page's kebab menu.
enum IssueDetailMenuAction { editIssue, openInBrowser }

/// Opens the issue detail overflow menu as a dropdown anchored at [position]
/// (computed from the kebab button's `RenderBox`) and returns the selected
/// action, or `null` if the user dismissed by tapping outside.
///
/// Anchored dropdowns beat bottom sheets for quick 2-item overflow menus
/// triggered from a top-corner button: the menu sprouts next to the finger
/// instead of forcing a round trip to the bottom of the screen.
Future<IssueDetailMenuAction?> showIssueDetailMenu(
  BuildContext context,
  RelativeRect position,
  bool canEditIssue,
) {
  final surfaceLowest = resolveColor(
    context,
    ColorTokens.surface.containerLowest,
  );
  final surfaceHighest = resolveColor(
    context,
    ColorTokens.surface.containerHighest,
  );
  final onSurface = resolveColor(context, ColorTokens.surface.on);
  final primary = resolveColor(context, ColorTokens.primary.$default);

  return showMenu<IssueDetailMenuAction>(
    context: context,
    position: position,
    color: surfaceLowest,
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    shadowColor: withOpacity(onSurface, 0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(editorialRadiusMedium),
    ),
    constraints: const BoxConstraints(minWidth: 208, maxWidth: 280),
    items: [
      _menuItem(
        context,
        key: const ValueKey('issue-detail-menu-edit'),
        value: IssueDetailMenuAction.editIssue,
        icon: LucideIcons.pencil,
        label: 'Edit Issue',
        enabled: canEditIssue,
        iconColor: primary,
        labelColor: onSurface,
        hoverColor: surfaceHighest,
      ),
      _menuItem(
        context,
        key: const ValueKey('issue-detail-menu-open-in-browser'),
        value: IssueDetailMenuAction.openInBrowser,
        icon: LucideIcons.externalLink,
        label: 'Open in Browser',
        enabled: true,
        iconColor: primary,
        labelColor: onSurface,
        hoverColor: surfaceHighest,
      ),
    ],
  );
}

/// Builds a custom-styled [PopupMenuItem] whose tap feedback is handled by the
/// host `showMenu` overlay (so we don't render our own `PressableBox`).
PopupMenuItem<IssueDetailMenuAction> _menuItem(
  BuildContext context, {
  required Key key,
  required IssueDetailMenuAction value,
  required IconData icon,
  required String label,
  required bool enabled,
  required Color iconColor,
  required Color labelColor,
  required Color hoverColor,
}) {
  return PopupMenuItem<IssueDetailMenuAction>(
    key: key,
    value: value,
    enabled: enabled,
    padding: EdgeInsets.zero,
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: withOpacity(iconColor, enabled ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(editorialRadiusSmall),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: enabled ? iconColor : withOpacity(labelColor, 0.45),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: resolveTextStyle(
                context,
                TextTokens.body.$medium,
              ).copyWith(
                color: enabled ? labelColor : withOpacity(labelColor, 0.45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
