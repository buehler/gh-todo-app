import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shared/editorial_text_link.dart';
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
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 8,
          children: [
            EditorialTextLink(
              label: 'Privacy Policy',
              onPressed: onPrivacyPressed,
            ),
            EditorialTextLink(
              label: 'Terms of Service',
              onPressed: onTermsPressed,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StatusBlip(),
            const SizedBox(width: 8),
            StyledText(
              'Operational: All Systems Go',
              style: editorialTextStyle(
                TextTokens.body.$small,
                color: withOpacity(onSurfaceVariant, 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
