import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class ConnectSecurityNotice extends StatelessWidget {
  const ConnectSecurityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.secondary.onFixedVariant,
    );

    return EditorialCard(
      variation: CardVariation.recessed,
      padding: const EdgeInsets.all(20),
      child: RowBox(
        style: editorialRowStyle(
          spacing: 14,
          crossAxis: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
        ),
        children: [
          StyledIcon(
            icon: LucideIcons.shieldCheck,
            style: editorialIconStyle(color: primary, size: 20),
          ),
          Expanded(
            child: StyledText(
              'We use your token only for local authentication. Your secret never leaves your devices\'s encrypted storage.',
              style: editorialTextStyle(
                TextTokens.body.$small,
                color: onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
