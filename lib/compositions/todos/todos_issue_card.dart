import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/todos/priority_badge.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Issue row for the project feed.
///
/// Layout: priority badge (optional) + title + comment count on top, muted
/// metadata footer (due date, #number, created, updated) below. When the
/// issue has a resolved priority, the card gets a colored left stripe via
/// [EditorialCard]'s `accent` variation.
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
    final outline = resolveColor(context, ColorTokens.outline.$default);

    final priority = issue.priority;
    final accentColor = priority == null
        ? null
        : resolveColor(context, tokensFor(priority).fg);

    return EditorialCard(
      variation: priority == null
          ? CardVariation.elevated
          : CardVariation.accent,
      accentColor: accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 12,
          crossAxis: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
        ),
        children: [
          RowBox(
            style: editorialRowStyle(
              spacing: 10,
              mainAxis: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxis: CrossAxisAlignment.start,
            ),
            children: [
              if (priority != null) PriorityBadge(priority: priority),
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
          _MetaFooter(issue: issue, outline: outline),
        ],
      ),
    );
  }
}

/// Muted single-line footer of auxiliary issue metadata. Due date (when set)
/// is emphasised slightly; number + created/updated use the outline color.
class _MetaFooter extends StatelessWidget {
  final IssueData issue;
  final Color outline;

  const _MetaFooter({required this.issue, required this.outline});

  @override
  Widget build(BuildContext context) {
    final dueDate = issue.dueDate;

    final mutedTextStyle = editorialTextStyle(
      TextTokens.label.$small,
      color: outline,
      fontWeight: FontWeight.w600,
    );

    final dueStyle = editorialTextStyle(
      TextTokens.label.$small,
      color: outline,
      fontWeight: FontWeight.w800,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (dueDate != null)
          _MetaItem(
            icon: LucideIcons.calendarClock,
            label: formatDueDate(dueDate),
            style: dueStyle,
            iconColor: outline,
          ),
        _MetaItem(
          label: '#${issue.number}',
          style: mutedTextStyle,
          iconColor: outline,
        ),
        _MetaItem(
          label: 'created ${formatRelative(issue.createdAt)}',
          style: mutedTextStyle,
          iconColor: outline,
        ),
        _MetaItem(
          label: 'updated ${formatRelative(issue.updatedAt)}',
          style: mutedTextStyle,
          iconColor: outline,
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final TextStyler style;
  final Color iconColor;

  const _MetaItem({
    this.icon,
    required this.label,
    required this.style,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          StyledIcon(
            icon: icon,
            style: editorialIconStyle(color: iconColor, size: 12),
          ),
          const SizedBox(width: 4),
        ],
        StyledText(label, style: style),
      ],
    );
  }
}
