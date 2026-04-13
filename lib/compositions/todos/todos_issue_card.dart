import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// A simplified issue row showing the title and comment count.
class TodosIssueCard extends StatelessWidget {
  final IssueData issue;

  const TodosIssueCard({required this.issue, super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return EditorialCard(
      variation: CardVariation.elevated,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: RowBox(
        style: editorialRowStyle(
          spacing: 12,
          mainAxis: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxis: CrossAxisAlignment.center,
        ),
        children: [
          Expanded(
            child: StyledText(
              issue.title,
              style: editorialTextStyle(
                TextTokens.title.$medium,
                color: onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (issue.commentCount > 0)
            RowBox(
              style: editorialRowStyle(spacing: 5),
              children: [
                StyledIcon(
                  icon: LucideIcons.messageSquare,
                  style: editorialIconStyle(
                    color: onSurfaceVariant,
                    size: 14,
                  ),
                ),
                StyledText(
                  '${issue.commentCount}',
                  style: editorialTextStyle(
                    TextTokens.label.$medium,
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
