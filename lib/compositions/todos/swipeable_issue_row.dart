import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/todos/todos_issue_card.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Wraps a [TodosIssueCard] with a trailing-swipe action pane that lets the
/// user close (or, for already-closed issues, re-open) the issue without
/// navigating to the detail page.
///
/// The card itself is rendered unchanged — the swipe pane is layered behind it
/// by [Slidable]. Tapping the pane fires the matching mutation through
/// [issueMutationsProvider]; the provider invalidates `projectIssuesProvider`,
/// which re-homes the card between the "Open" and "Recently closed" sections
/// on the next rebuild.
///
/// Design notes (see `design/DESIGN.md`):
/// - The pane matches [editorialRadiusLarge] on its exposed (right) corners so
///   the seam with the card is radius-continuous.
/// - No dividers, no borders, no shadow — boundary is carried purely by the
///   tonal shift behind the card.
/// - Tones are container-family (`tertiary.container` for close,
///   `primary.container` for reopen). No saturated red — closing an issue is
///   not an error state.
class SwipeableIssueRow extends ConsumerStatefulWidget {
  const SwipeableIssueRow({
    required this.issue,
    required this.projectId,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  final IssueData issue;
  final String projectId;
  final bool enabled;
  final VoidCallback? onTap;

  /// Key on the outer [Slidable], scoped per issue id — used by widget tests
  /// to target a specific row with `tester.drag(...)`.
  static ValueKey<String> rowKey(String issueId) =>
      ValueKey('swipeable-issue-row-$issueId');

  /// Key on the reveal pane itself — used by widget tests to tap the Close /
  /// Reopen action after the pane has been dragged open.
  static ValueKey<String> actionPaneKey(String issueId) =>
      ValueKey('swipeable-issue-row-action-$issueId');

  @override
  ConsumerState<SwipeableIssueRow> createState() => _SwipeableIssueRowState();
}

class _SwipeableIssueRowState extends ConsumerState<SwipeableIssueRow> {
  Future<void> _toggleState() async {
    HapticFeedback.selectionClick();

    final mutations = ref.read(issueMutationsProvider);
    final wasClosed = widget.issue.closed;
    try {
      if (wasClosed) {
        await mutations.reopenIssue(
          projectId: widget.projectId,
          issueId: widget.issue.id,
        );
      } else {
        await mutations.closeIssue(
          projectId: widget.projectId,
          issueId: widget.issue.id,
        );
      }
      // On success, `projectIssuesProvider` invalidation inside the mutation
      // rebuilds the list and the card teleports to the matching section.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasClosed
                ? 'Failed to re-open the issue.'
                : 'Failed to close the issue.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.issue.closed;
    if (!widget.enabled) {
      return TodosIssueCard(issue: widget.issue, onTap: widget.onTap);
    }

    return Slidable(
      key: SwipeableIssueRow.rowKey(widget.issue.id),
      // Opening one row closes any other open row in the feed — iOS Mail
      // convention and avoids multiple hanging panes.
      groupTag: 'root-feed',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.28,
        // Tap-to-commit only; full-drag dismissal is out of scope.
        dragDismissible: false,
        children: [
          CustomSlidableAction(
            key: SwipeableIssueRow.actionPaneKey(widget.issue.id),
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            // Match the card's rounded corners so the pane's right edge meets
            // the card without a square corner peeking out.
            borderRadius: const BorderRadius.all(
              Radius.circular(editorialRadiusLarge),
            ),
            // `autoClose: true` (the default) dismisses the pane as soon as
            // the user lifts off — no manual close() across async gaps.
            onPressed: (_) => _toggleState(),
            child: _SwipeActionPanel(isClosed: isClosed),
          ),
        ],
      ),
      child: TodosIssueCard(issue: widget.issue, onTap: widget.onTap),
    );
  }
}

/// The visual pane revealed behind the card on a trailing swipe. Stays
/// deliberately flat (no shadow, no border) — in the Editorial Tech language
/// the pane's presence is communicated by tone alone.
class _SwipeActionPanel extends StatelessWidget {
  const _SwipeActionPanel({required this.isClosed});

  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    // `isClosed` reflects the issue's current state — which determines the
    // action the pane offers (reopen when closed, close when open).
    final bg = resolveColor(
      context,
      isClosed ? ColorTokens.primary.container : ColorTokens.tertiary.container,
    );
    final fg = resolveColor(
      context,
      isClosed ? ColorTokens.primary.on : ColorTokens.tertiary.onContainer,
    );

    return Box(
      style: BoxStyler()
          .color(bg)
          .borderRounded(editorialRadiusLarge)
          .clipBehavior(Clip.antiAlias),
      child: Center(
        child: ColumnBox(
          style: editorialColumnStyle(
            spacing: 6,
            crossAxis: CrossAxisAlignment.center,
            mainAxis: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          ),
          children: [
            StyledIcon(
              icon: isClosed ? LucideIcons.refreshCw : LucideIcons.circleCheck,
              style: editorialIconStyle(color: fg, size: 20),
            ),
            StyledText(
              isClosed ? 'REOPEN' : 'CLOSE',
              style: editorialTextStyle(
                TextTokens.label.$small,
                color: fg,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
