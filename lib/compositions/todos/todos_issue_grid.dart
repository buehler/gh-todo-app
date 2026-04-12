import 'package:flutter/material.dart';
import 'package:gh_todos/compositions/todos/todos_issue_card.dart';
import 'package:gh_todos/services/mock_todos_data.dart';

/// A bento-style responsive grid of issue cards for a single [TodoGroup].
///
/// Under 720 wide we stack vertically. Above that we arrange cards in rows
/// with different flex weights to evoke the editorial layout from the design
/// mockup (8/4 for the Design System group, 6/6 for the API V2 group).
class TodosIssueGrid extends StatelessWidget {
  final TodoGroup group;

  const TodosIssueGrid({required this.group, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final rows = _layoutRows(group);

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < group.issues.length; i++) ...[
                TodosIssueCard(
                  issue: group.issues[i],
                  featured: i == 0 && group.issues[i].priority ==
                      IssuePriority.high,
                ),
                if (i < group.issues.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      Expanded(
                        flex: rows[r][c].flex,
                        child: TodosIssueCard(
                          issue: rows[r][c].issue,
                          featured: rows[r][c].featured,
                        ),
                      ),
                      if (c < rows[r].length - 1) const SizedBox(width: 16),
                    ],
                  ],
                ),
              ),
              if (r < rows.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _GridCell {
  final TodoIssue issue;
  final int flex;
  final bool featured;

  const _GridCell(this.issue, this.flex, {this.featured = false});
}

/// Pair issues into rows. The first issue in each group is featured on wide
/// screens; subsequent issues fill in evenly beside or below it.
List<List<_GridCell>> _layoutRows(TodoGroup group) {
  final issues = group.issues;
  if (issues.isEmpty) return const [];

  final rows = <List<_GridCell>>[];
  var i = 0;

  // Row 1: featured card (8/12) + optional neighbour (4/12).
  if (issues.length == 1) {
    rows.add([_GridCell(issues[0], 1, featured: true)]);
    return rows;
  }

  if (issues[0].priority == IssuePriority.high) {
    rows.add([
      _GridCell(issues[0], 8, featured: true),
      _GridCell(issues[1], 4),
    ]);
    i = 2;
  }

  // Remaining rows: pairs of equal-weight cards, or a single centered card.
  while (i < issues.length) {
    if (i + 1 < issues.length) {
      rows.add([_GridCell(issues[i], 1), _GridCell(issues[i + 1], 1)]);
      i += 2;
    } else {
      rows.add([_GridCell(issues[i], 1)]);
      i += 1;
    }
  }

  return rows;
}
