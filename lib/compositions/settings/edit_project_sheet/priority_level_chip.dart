import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Pill-shaped label for a [TodoPriority], styled like the priority chips
/// in `design/prio.html` §07 Semantics.
///
/// Colors come from the theme (`ColorTokens.priority.<level>.fg/bg`), so the
/// chip renders correctly under any current or future theme without code
/// changes here.
class PriorityLevelChip extends StatelessWidget {
  final TodoPriority priority;

  /// When true, renders only the colored dot on the chip background
  /// (no label). Useful in compact dropdown rows.
  final bool compact;

  const PriorityLevelChip({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = tokensFor(priority);
    final fg = resolveColor(context, tokens.fg);
    final bg = resolveColor(context, tokens.bg);

    return Box(
      style: BoxStyler()
          .color(bg)
          .borderRounded(10)
          .paddingOnly(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 7,
          ),
      child: RowBox(
        style: editorialRowStyle(spacing: 6),
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          if (!compact)
            StyledText(
              priorityLabels[priority]!.toUpperCase(),
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
