import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Small pill badge rendering a [TodoPriority] as a colored dot + uppercase
/// label. Colors are resolved from `tokensFor(priority)` — see
/// `design/prio.html` §07 for the visual spec.
class PriorityBadge extends StatelessWidget {
  final TodoPriority priority;

  const PriorityBadge({required this.priority, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = tokensFor(priority);
    final fg = resolveColor(context, tokens.fg);
    final bg = resolveColor(context, tokens.bg);
    final label = priorityLabels[priority]!;

    return Box(
      style: BoxStyler()
          .color(bg)
          .borderRounded(8)
          .paddingOnly(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          StyledText(
            label.toUpperCase(),
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
