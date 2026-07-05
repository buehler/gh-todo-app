import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/pages/issue_detail_page.dart';
import 'package:gh_todos/providers/selected_issue_provider.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Wraps the todos branch content (the list) and — on wide layouts — pairs
/// it with an inline issue-detail pane driven by [selectedIssueProvider].
///
/// On compact/medium widths this is a pass-through: returns [child] directly
/// so navigation still push-routes to the full-screen [IssueDetailPage].
///
/// The boundary between panes is tonal (no 1px line): the list pane sits on
/// `surface`, the detail pane on `surface.containerLowest`.
class TodosSplitView extends ConsumerWidget {
  static const pageKey = ValueKey('todos-split-view');
  static const detailPaneKey = ValueKey('todos-split-detail-pane');
  static const detailPaneEmptyKey = ValueKey('todos-split-detail-empty');

  final Widget child;
  final Widget? detail;

  const TodosSplitView({required this.child, this.detail, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isWide(context)) {
      return child;
    }

    final selected = ref.watch(selectedIssueProvider);
    final detail = this.detail;

    return Row(
      key: pageKey,
      children: [
        // List pane — sits on `surface` so it reads as the "main" column.
        Expanded(flex: 4, child: child),
        // Detail pane — tonal step up to `surface.containerLowest` provides
        // the boundary (DESIGN.md "No-Line Rule"). The page inside still
        // manages its own scroll + top bar.
        Expanded(
          key: detailPaneKey,
          flex: 6,
          child: ColoredBox(
            color: resolveColor(context, ColorTokens.surface.containerLowest),
            child:
                detail ??
                (selected == null
                    ? const _EmptyDetailPane()
                    : IssueDetailPage(
                        // Key on the selected issue id so that switching rows
                        // tears down the previous detail state cleanly.
                        key: ValueKey('issue-detail-pane-${selected.id}'),
                        issueId: selected.id,
                        issue: selected,
                        embedded: true,
                      )),
          ),
        ),
      ],
    );
  }
}

class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceContainerLow = resolveColor(
      context,
      ColorTokens.surface.containerLow,
    );

    return Center(
      key: TodosSplitView.detailPaneEmptyKey,
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 16,
          crossAxis: CrossAxisAlignment.center,
          mainAxis: MainAxisAlignment.center,
        ),
        children: [
          Box(
            style: BoxStyler()
                .width(72)
                .height(72)
                .color(surfaceContainerLow)
                .borderRounded(999)
                .alignment(Alignment.center),
            child: StyledIcon(
              icon: LucideIcons.fileText,
              style: editorialIconStyle(color: onSurfaceVariant, size: 28),
            ),
          ),
          StyledText(
            'Select an issue',
            style: editorialTextStyle(
              TextTokens.title.$medium,
              color: resolveColor(context, ColorTokens.surface.on),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(
            width: 280,
            child: StyledText(
              'Pick a todo from the list to see its full story — '
              'description, conversation, and quick edits.',
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: onSurfaceVariant,
              ).textAlign(TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
