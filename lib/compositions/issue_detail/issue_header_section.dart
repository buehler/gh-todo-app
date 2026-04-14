import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/todos/priority_badge.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Top section of the issue detail page: a vertical priority-colored stripe,
/// title + `#number`, then the metadata row (priority badge, due-date pill,
/// "updated Xago" note).
class IssueHeaderSection extends StatelessWidget {
  static const pageKey = ValueKey('issue-header-section');

  final IssueData issue;

  const IssueHeaderSection({required this.issue, super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final tertiary = resolveColor(context, ColorTokens.tertiary.$default);
    final secondaryContainer = resolveColor(
      context,
      ColorTokens.secondary.container,
    );
    final onSecondaryFixedVariant = resolveColor(
      context,
      ColorTokens.secondary.onFixedVariant,
    );

    final priority = issue.priority;
    final stripeColor = priority != null
        ? resolveColor(context, tokensFor(priority).fg)
        : tertiary;

    return ColumnBox(
      key: pageKey,
      style: editorialColumnStyle(
        spacing: 16,
        crossAxis: CrossAxisAlignment.start,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: resolveTextStyle(context, TextTokens.headline.$medium)
                      .copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                  children: [
                    TextSpan(text: issue.title),
                    TextSpan(
                      text: '  #${issue.number}',
                      style: resolveTextStyle(context, TextTokens.title.$medium)
                          .copyWith(
                            color: withOpacity(onSurfaceVariant, 0.6),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (priority != null) PriorityBadge(priority: priority),
            if (issue.dueDate != null)
              _MetaPill(
                icon: LucideIcons.calendarClock,
                label: formatDueDate(issue.dueDate!),
                fg: onSecondaryFixedVariant,
                bg: secondaryContainer,
              ),
            if (issue.closed && issue.closedAt != null)
              _MetaNote(
                label: 'Closed ${formatRelative(issue.closedAt!)}',
                color: onSurfaceVariant,
              )
            else
              _MetaNote(
                label: 'Updated ${formatRelative(issue.updatedAt)}',
                color: onSurfaceVariant,
              ),
          ],
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .color(bg)
          .borderRounded(999)
          .paddingOnly(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledIcon(
            icon: icon,
            style: editorialIconStyle(color: fg, size: 14),
          ),
          const SizedBox(width: 6),
          StyledText(
            label.toUpperCase(),
            style: editorialTextStyle(
              TextTokens.label.$small,
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaNote extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaNote({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: StyledText(
        label,
        style: editorialTextStyle(
          TextTokens.label.$medium,
          color: withOpacity(color, 0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
