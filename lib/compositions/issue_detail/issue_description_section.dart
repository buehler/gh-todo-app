import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// "Description" section — section heading + a card containing the issue's
/// GitHub-rendered HTML body.
///
/// Reads the local issue detail snapshot. Comments load separately.
class IssueDescriptionSection extends StatelessWidget {
  static const pageKey = ValueKey('issue-description-section');

  final IssueDetails details;
  final Future<void> Function(int taskIndex, bool checked)? onTaskToggle;
  final bool taskToggleBusy;

  const IssueDescriptionSection({
    required this.details,
    this.onTaskToggle,
    this.taskToggleBusy = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    return ColumnBox(
      key: pageKey,
      style: editorialColumnStyle(
        spacing: 12,
        crossAxis: CrossAxisAlignment.stretch,
      ),
      children: [
        StyledText(
          'Description',
          style: editorialTextStyle(
            TextTokens.title.$large,
            color: onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        EditorialCard(
          variation: CardVariation.recessed,
          padding: const EdgeInsets.all(20),
          child: GithubHtmlBody(
            html: details.bodyHtml,
            emptyText: 'No description provided.',
            onTaskToggle: onTaskToggle,
            taskToggleBusy: taskToggleBusy,
          ),
        ),
      ],
    );
  }
}
