import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shared/legal_links_row.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

class ConnectFooter extends StatelessWidget {
  final VoidCallback onPrivacyPressed;
  final VoidCallback onTermsPressed;

  const ConnectFooter({
    required this.onPrivacyPressed,
    required this.onTermsPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColumnBox(
      style: editorialColumnStyle(
        spacing: 16,
        crossAxis: CrossAxisAlignment.center,
        width: double.infinity,
      ),
      children: [
        LegalLinksRow(
          onPrivacyPressed: onPrivacyPressed,
          onTermsPressed: onTermsPressed,
        ),
        RowBox(
          style: editorialRowStyle(spacing: 8),
          children: [
            Box(
              style: BoxStyler()
                  .width(6)
                  .height(6)
                  .color(resolveColor(context, ColorTokens.primary.$default))
                  .borderRounded(999),
            ),
            StyledText(
              'Operational: All Systems Go',
              style: editorialTextStyle(
                TextTokens.body.$small,
                color: resolveColor(
                  context,
                  ColorTokens.surface.onVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
