import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shared/editorial_text_link.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class ConnectTokenForm extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onConnectPressed;
  final VoidCallback onHelpPressed;
  final String? errorText;
  final bool isSubmitting;

  const ConnectTokenForm({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onConnectPressed,
    required this.onHelpPressed,
    required this.isSubmitting,
    this.errorText,
    super.key,
  });

  bool get _isValid => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return EditorialCard(
      variation: CardVariation.recessed,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StyledText(
                  'Personal Access Token',
                  style: editorialTextStyle(
                    TextTokens.label.$large,
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              EditorialTextLink(
                label: 'How to create one?',
                onPressed: onHelpPressed,
                leadingIcon: LucideIcons.circleQuestionMark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          EditorialTextField(
            controller: controller,
            hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
            prefixIcon: LucideIcons.keyRound,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.done,
            autofocus: false,
            errorText: errorText,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: EditorialButton(
              label: 'Get Started',
              trailingIcon: LucideIcons.arrowRight,
              onPressed: onConnectPressed,
              enabled: _isValid && !isSubmitting,
              loading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}
