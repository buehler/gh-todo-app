import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// "Description" section — section heading + a card containing the issue's
/// `bodyText` as selectable plain text.
///
/// Reads the local issue detail snapshot. Comments load separately.
class IssueDescriptionSection extends StatelessWidget {
  static const pageKey = ValueKey('issue-description-section');

  final IssueDetails details;

  const IssueDescriptionSection({required this.details, super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

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
          child: Builder(
            builder: (context) {
              final body = details.description;
              if (body == null) {
                return StyledText(
                  'No description provided.',
                  style: editorialTextStyle(
                    TextTokens.body.$medium,
                    color: withOpacity(onSurfaceVariant, 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return SelectableText(
                body,
                style: resolveTextStyle(
                  context,
                  TextTokens.body.$medium,
                ).copyWith(color: onSurfaceVariant, height: 1.5),
              );
            },
          ),
        ),
      ],
    );
  }
}
