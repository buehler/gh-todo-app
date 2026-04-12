import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Blue uppercase section label used to separate settings groups.
class SettingsSectionHeader extends StatelessWidget {
  final String label;

  const SettingsSectionHeader({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: StyledText(
        label,
        style: editorialTextStyle(
          TextTokens.label.$small,
          color: primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ).uppercase(),
      ),
    );
  }
}
