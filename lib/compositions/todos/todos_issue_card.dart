import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/services/mock_todos_data.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Renders a single issue card, picking an `EditorialCard` variation based
/// on the issue's priority.
class TodosIssueCard extends StatelessWidget {
  final TodoIssue issue;
  final bool featured;

  const TodosIssueCard({
    required this.issue,
    this.featured = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final variation = switch (issue.priority) {
      IssuePriority.high => CardVariation.accent,
      IssuePriority.standard => CardVariation.elevated,
      IssuePriority.closed => CardVariation.recessed,
    };
    final accentColor = issue.priority == IssuePriority.high
        ? resolveColor(context, ColorTokens.tertiary.$default)
        : null;

    return EditorialCard(
      variation: variation,
      accentColor: accentColor,
      padding: const EdgeInsets.all(24),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 18,
          crossAxis: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
        ).width(double.infinity),
        children: [
          _TopRow(issue: issue),
          _Title(issue: issue, featured: featured),
          _Footer(issue: issue),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final TodoIssue issue;

  const _TopRow({required this.issue});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final error = resolveColor(context, ColorTokens.error.$default);
    final dueColor = issue.status == IssueStatus.overdue
        ? error
        : onSurfaceVariant;

    // Closed issues surface the due label in the footer row, so we skip it
    // at the top to avoid duplicating it (and overflowing narrow cards).
    final showTopDueLabel =
        issue.dueLabel != null && issue.status != IssueStatus.closed;

    return RowBox(
      style: editorialRowStyle(
        spacing: 12,
        mainAxis: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxis: CrossAxisAlignment.start,
      ),
      children: [
        Flexible(child: _TypeChip(issue: issue)),
        if (showTopDueLabel)
          Flexible(
            child: _DueLabel(
              label: issue.dueLabel!,
              color: dueColor,
              showIcon: issue.status != IssueStatus.overdue &&
                  issue.status != IssueStatus.noDate,
            ),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final TodoIssue issue;

  const _TypeChip({required this.issue});

  @override
  Widget build(BuildContext context) {
    final tertiary = resolveColor(context, ColorTokens.tertiary.$default);
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final secondary = resolveColor(context, ColorTokens.secondary.$default);

    return switch (issue.typeTag) {
      IssueTypeTag.highPriority => EditorialChip(
        label: 'High Priority',
        variation: ChipVariation.status,
        leadingDotColor: tertiary,
      ),
      IssueTypeTag.refactor => EditorialChip(
        label: 'Refactor',
        variation: ChipVariation.status,
        leadingDotColor: secondary,
      ),
      IssueTypeTag.bug => EditorialChip(
        label: 'Bug',
        variation: ChipVariation.status,
        leadingDotColor: primary,
      ),
      IssueTypeTag.core => EditorialChip(
        label: 'Core',
        variation: ChipVariation.status,
        leadingDotColor: primary,
      ),
    };
  }
}

class _DueLabel extends StatelessWidget {
  final String label;
  final Color color;
  final bool showIcon;

  const _DueLabel({
    required this.label,
    required this.color,
    required this.showIcon,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = resolveTextStyle(
      context,
      TextTokens.label.$small,
    ).copyWith(color: color, fontWeight: FontWeight.w700);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          StyledIcon(
            icon: LucideIcons.calendarDays,
            style: editorialIconStyle(color: color, size: 14),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final TodoIssue issue;
  final bool featured;

  const _Title({required this.issue, required this.featured});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    return StyledText(
      issue.title,
      style: editorialTextStyle(
        featured ? TextTokens.title.$large : TextTokens.title.$medium,
        color: onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final TodoIssue issue;

  const _Footer({required this.issue});

  @override
  Widget build(BuildContext context) {
    if (issue.status == IssueStatus.closed) {
      return _ClosedRow(label: issue.dueLabel ?? 'Closed');
    }

    final hasCounters = issue.commentCount > 0 || issue.attachmentCount > 0;
    final hasAssignees = issue.assigneeInitials.isNotEmpty;

    return RowBox(
      style: editorialRowStyle(
        spacing: 12,
        mainAxis: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
      ),
      children: [
        const _StatusRow(),
        if (hasAssignees)
          _AssigneeStack(initials: issue.assigneeInitials)
        else if (hasCounters)
          _CounterRow(
            commentCount: issue.commentCount,
            attachmentCount: issue.attachmentCount,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return RowBox(
      style: editorialRowStyle(spacing: 8),
      children: [
        const StatusBlip(size: 10),
        StyledText(
          'Open',
          style: editorialTextStyle(
            TextTokens.label.$large,
            color: onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ClosedRow extends StatelessWidget {
  final String label;

  const _ClosedRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final outline = resolveColor(context, ColorTokens.outline.$default);
    final labelStyle = resolveTextStyle(
      context,
      TextTokens.label.$large,
    ).copyWith(color: outline, fontWeight: FontWeight.w600);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StyledIcon(
          icon: LucideIcons.circleCheck,
          style: editorialIconStyle(color: outline, size: 16),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  final int commentCount;
  final int attachmentCount;

  const _CounterRow({
    required this.commentCount,
    required this.attachmentCount,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return RowBox(
      style: editorialRowStyle(spacing: 16),
      children: [
        if (commentCount > 0)
          _Counter(
            icon: LucideIcons.messageSquare,
            value: commentCount,
            color: onSurfaceVariant,
          ),
        if (attachmentCount > 0)
          _Counter(
            icon: LucideIcons.paperclip,
            value: attachmentCount,
            color: onSurfaceVariant,
          ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _Counter({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: editorialRowStyle(spacing: 5),
      children: [
        StyledIcon(
          icon: icon,
          style: editorialIconStyle(color: color, size: 13),
        ),
        StyledText(
          '$value',
          style: editorialTextStyle(
            TextTokens.label.$medium,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AssigneeStack extends StatelessWidget {
  final List<String> initials;

  const _AssigneeStack({required this.initials});

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    const size = 28.0;
    const overlap = 10.0;

    return SizedBox(
      height: size,
      width: size + (initials.length - 1) * (size - overlap),
      child: Stack(
        children: [
          for (var i = 0; i < initials.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: _AssigneeAvatar(
                initial: initials[i],
                borderColor: surfaceLowest,
                size: size,
                index: i,
              ),
            ),
        ],
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  final String initial;
  final Color borderColor;
  final double size;
  final int index;

  const _AssigneeAvatar({
    required this.initial,
    required this.borderColor,
    required this.size,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final tones = [
      resolveColor(context, ColorTokens.primary.fixed),
      resolveColor(context, ColorTokens.tertiary.fixedDim),
      resolveColor(context, ColorTokens.secondary.container),
    ];
    final bg = tones[index % tones.length];
    final fg = resolveColor(context, ColorTokens.surface.on);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
