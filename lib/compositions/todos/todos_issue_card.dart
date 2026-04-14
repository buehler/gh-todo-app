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
/// Open cards get the priority badge (if mapped) + colored left stripe.
/// Closed cards are dimmed via the card's `enabled: false` flag and show a
/// "Done" pill where the priority badge would otherwise sit.
class TodosIssueCard extends StatelessWidget {
  final IssueData issue;
  final VoidCallback? onTap;

  const TodosIssueCard({required this.issue, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final outline = resolveColor(context, ColorTokens.outline.$default);

    final priority = issue.priority;
    final showAccent = !issue.closed && priority != null;
    final accentColor = showAccent
        ? resolveColor(context, tokensFor(priority).fg)
        : null;

    // Closed cards stay tappable (so the detail page — and the re-open button
    // there — remain reachable), but are visually dimmed via an external
    // Opacity wrapper instead of EditorialCard's `enabled: false`, which would
    // also swallow the tap.
    final card = EditorialCard(
      onTap: onTap,
      variation: showAccent ? CardVariation.accent : CardVariation.elevated,
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
              if (issue.closed)
                const _DoneBadge()
              else if (priority != null)
                PriorityBadge(priority: priority),
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

    return issue.closed ? Opacity(opacity: 0.58, child: card) : card;
  }
}

/// "Done" pill shown on closed cards — dot + uppercase label, using the
/// primary-fixed palette (same family as an informational status chip).
class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    final fg = resolveColor(context, ColorTokens.primary.onFixedVariant);
    final bg = resolveColor(context, ColorTokens.primary.fixed);

    return Box(
      style: BoxStyler()
          .color(bg)
          .borderRounded(8)
          .paddingOnly(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledIcon(
            icon: LucideIcons.check,
            style: editorialIconStyle(color: fg, size: 12),
          ),
          const SizedBox(width: 4),
          StyledText(
            'DONE',
            style: editorialTextStyle(
              TextTokens.label.$small,
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted single-line footer of auxiliary issue metadata. Due date (when set)
/// is emphasised slightly; the rest uses the outline color. Closed issues
/// swap the "updated" line for "closed", which reads more naturally in the
/// "Recently closed" section.
class _MetaFooter extends StatelessWidget {
  final IssueData issue;
  final Color outline;

  const _MetaFooter({required this.issue, required this.outline});

  @override
  Widget build(BuildContext context) {
    final dueDate = issue.dueDate;
    final closedAt = issue.closedAt;

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

    final tailLabel = issue.closed && closedAt != null
        ? 'closed ${formatRelative(closedAt)}'
        : 'updated ${formatRelative(issue.updatedAt)}';

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (dueDate != null && !issue.closed)
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
        _MetaItem(label: tailLabel, style: mutedTextStyle, iconColor: outline),
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
