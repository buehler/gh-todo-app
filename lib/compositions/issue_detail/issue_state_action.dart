import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Call-to-action that toggles the issue's open/closed state.
///
/// Label + leading icon flip based on [IssueData.closed]: "Close Issue" with a
/// check when open, "Re-open Issue" with a refresh arrow when already closed.
///
/// The button's **variation** also flips so only one primary CTA is visible on
/// the page at a time: closing is the page's dominant action
/// ([ButtonVariation.primary], gradient fill); re-opening is a quieter
/// [ButtonVariation.secondary] (surface_container_high fill).
class IssueStateAction extends StatelessWidget {
  static const pageKey = ValueKey('issue-state-action');

  final IssueData issue;
  final VoidCallback? onPressed;

  /// Passed straight through to [EditorialButton] so the host page can disable
  /// the button while a state mutation is in flight.
  final bool enabled;

  const IssueStateAction({
    required this.issue,
    this.onPressed,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = !issue.closed;
    return SizedBox(
      key: pageKey,
      width: double.infinity,
      child: EditorialButton(
        label: isOpen ? 'Close Issue' : 'Re-open Issue',
        leadingIcon: isOpen ? LucideIcons.circleCheck : LucideIcons.refreshCw,
        variation: isOpen ? ButtonVariation.primary : ButtonVariation.secondary,
        enabled: enabled,
        onPressed: onPressed,
      ),
    );
  }
}
