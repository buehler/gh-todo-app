import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Primary call-to-action that toggles the issue's open/closed state.
///
/// Label + leading icon flip based on [IssueData.closed]: "Close Issue" with a
/// check when open, "Re-open Issue" with a refresh arrow when already closed.
///
/// Behavior is intentionally stubbed — wiring this to the GitHub mutation is a
/// follow-up, same as the detail-page FAB.
class IssueStateAction extends StatelessWidget {
  static const pageKey = ValueKey('issue-state-action');

  final IssueData issue;
  final VoidCallback? onPressed;

  const IssueStateAction({required this.issue, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final isOpen = !issue.closed;
    return SizedBox(
      key: pageKey,
      width: double.infinity,
      child: EditorialButton(
        label: isOpen ? 'Close Issue' : 'Re-open Issue',
        leadingIcon: isOpen ? LucideIcons.circleCheck : LucideIcons.refreshCw,
        onPressed: onPressed,
      ),
    );
  }
}
