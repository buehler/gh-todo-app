import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shared/editorial_text_link.dart';
import 'package:mix/mix.dart';

class LegalLinksRow extends StatelessWidget {
  final VoidCallback onPrivacyPressed;
  final VoidCallback onTermsPressed;

  const LegalLinksRow({
    required this.onPrivacyPressed,
    required this.onTermsPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: editorialRowStyle(spacing: 20),
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
    );
  }
}
