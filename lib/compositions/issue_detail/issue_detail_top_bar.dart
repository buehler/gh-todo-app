import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/issue_detail/issue_detail_menu.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Frosted top bar for the issue detail page.
///
/// Mirrors the `AppTopBar` recipe (blur + translucent surface + safe-area
/// padding), but with a back chevron on the leading edge, "Issue Details"
/// title, and a trailing kebab menu anchored dropdown. No avatar.
class IssueDetailTopBar extends StatefulWidget {
  static const double barHeight = 64;
  static const pageKey = ValueKey('issue-detail-top-bar');
  static const backButtonKey = ValueKey('issue-detail-top-bar-back');

  final VoidCallback onBack;

  /// Called with the user's selection when the kebab menu resolves to an
  /// action. Not invoked when the menu is dismissed without a choice.
  final ValueChanged<IssueDetailMenuAction>? onMenuAction;

  const IssueDetailTopBar({required this.onBack, this.onMenuAction, super.key});

  @override
  State<IssueDetailTopBar> createState() => _IssueDetailTopBarState();
}

class _IssueDetailTopBarState extends State<IssueDetailTopBar> {
  /// Attached to the kebab [IconButton] so we can read its `RenderBox` to
  /// position the dropdown right under the trigger.
  final GlobalKey _menuButtonKey = GlobalKey();

  Future<void> _openMenu() async {
    final anchorContext = _menuButtonKey.currentContext;
    if (anchorContext == null) return;

    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) return;

    // Position the menu's top-right corner at the anchor's bottom-right,
    // so it appears to drop from the kebab.
    final anchorSize = anchorBox.size;
    final anchorBottomRight = anchorBox.localToGlobal(
      Offset(anchorSize.width, anchorSize.height),
      ancestor: overlayBox,
    );
    final position = RelativeRect.fromLTRB(
      anchorBottomRight.dx,
      anchorBottomRight.dy,
      overlayBox.size.width - anchorBottomRight.dx,
      0,
    );

    final action = await showIssueDetailMenu(context, position);
    if (action != null) widget.onMenuAction?.call(action);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceBright = resolveColor(context, ColorTokens.surface.bright);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final safeTop = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Box(
          key: IssueDetailTopBar.pageKey,
          style: BoxStyler()
              .color(withOpacity(surfaceBright, 0.8))
              .height(IssueDetailTopBar.barHeight + safeTop)
              .paddingOnly(top: safeTop, horizontal: 12),
          child: Row(
            children: [
              IconButton(
                key: IssueDetailTopBar.backButtonKey,
                onPressed: widget.onBack,
                icon: Icon(LucideIcons.arrowLeft, color: onSurfaceVariant),
                splashRadius: 22,
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: StyledText(
                  'Issue Details',
                  style: editorialTextStyle(
                    TextTokens.title.$large,
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              IconButton(
                key: _menuButtonKey,
                onPressed: _openMenu,
                icon: Icon(LucideIcons.ellipsis, color: onSurfaceVariant),
                splashRadius: 22,
                tooltip: 'More actions',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
