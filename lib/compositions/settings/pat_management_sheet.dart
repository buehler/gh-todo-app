import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/adaptive_sheet.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

enum PatAction { update, remove }

/// Shows a sheet (or centered dialog on wide) with PAT management actions:
/// update or remove.
Future<PatAction?> showPatManagementSheet(BuildContext context) {
  return showAdaptiveSheet<PatAction>(
    context,
    isScrollControlled: false,
    builder: (_, isDialog) => _PatManagementSheet(isDialog: isDialog),
  );
}

/// Shows a sheet (or centered dialog on wide) with a text field to enter a
/// new PAT. Returns the new token string or `null` if dismissed.
Future<String?> showPatUpdateSheet(BuildContext context) {
  return showAdaptiveSheet<String>(
    context,
    builder: (_, isDialog) => _PatUpdateSheet(isDialog: isDialog),
  );
}

class _PatManagementSheet extends StatelessWidget {
  final bool isDialog;

  const _PatManagementSheet({required this.isDialog});

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final error = resolveColor(context, ColorTokens.error.$default);
    final errorContainer = resolveColor(context, ColorTokens.error.container);
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSheetDragHandle(isDialog: isDialog),
        // Title + masked token
        Padding(
          padding: EdgeInsets.fromLTRB(24, isDialog ? 24 : 0, 24, 8),
          child: ColumnBox(
            style: editorialColumnStyle(
              spacing: 4,
              crossAxis: CrossAxisAlignment.start,
            ),
            children: [
              StyledText(
                'Personal Access Token',
                style: editorialTextStyle(
                  TextTokens.title.$large,
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              StyledText(
                '••••••••••••••••',
                style: editorialTextStyle(
                  TextTokens.body.$small,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Update action
        _ActionRow(
          icon: LucideIcons.refreshCw,
          iconColor: primary,
          iconBgColor: withOpacity(primary, 0.1),
          label: 'Update Token',
          labelColor: onSurface,
          hoverColor: surfaceHighest,
          onTap: () => Navigator.pop(context, PatAction.update),
        ),
        // Remove action
        _ActionRow(
          icon: LucideIcons.trash2,
          iconColor: error,
          iconBgColor: withOpacity(errorContainer, 0.3),
          label: 'Remove Token',
          labelColor: error,
          hoverColor: surfaceHighest,
          onTap: () => Navigator.pop(context, PatAction.remove),
        ),
        SizedBox(
          height: isDialog ? 16 : MediaQuery.paddingOf(context).bottom + 96,
        ),
      ],
    );

    if (isDialog) return content;

    return Container(
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: content,
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final Color labelColor;
  final Color hoverColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.labelColor,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableBox(
      onPress: onTap,
      style: BoxStyler()
          .color(Colors.transparent)
          .paddingOnly(horizontal: 24, vertical: 14)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(hoverColor)),
      child: RowBox(
        style: editorialRowStyle(spacing: 16, mainAxisSize: MainAxisSize.max),
        children: [
          Box(
            style: BoxStyler()
                .width(40)
                .height(40)
                .color(iconBgColor)
                .borderRounded(editorialRadiusSmall)
                .alignment(Alignment.center),
            child: StyledIcon(
              icon: icon,
              style: editorialIconStyle(color: iconColor, size: 20),
            ),
          ),
          Expanded(
            child: StyledText(
              label,
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatUpdateSheet extends StatefulWidget {
  final bool isDialog;

  const _PatUpdateSheet({required this.isDialog});

  @override
  State<_PatUpdateSheet> createState() => _PatUpdateSheetState();
}

class _PatUpdateSheetState extends State<_PatUpdateSheet> {
  final _controller = TextEditingController();

  bool get _isValid => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSheetDragHandle(isDialog: widget.isDialog),
        Padding(
          padding: EdgeInsets.fromLTRB(24, widget.isDialog ? 24 : 0, 24, 16),
          child: StyledText(
            'Update Token',
            style: editorialTextStyle(
              TextTokens.title.$large,
              color: onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: EditorialTextField(
            controller: _controller,
            hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.done,
            autofocus: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: SizedBox(
            width: double.infinity,
            child: EditorialButton(
              label: 'Save Token',
              onPressed: _isValid ? _submit : null,
              enabled: _isValid,
            ),
          ),
        ),
        SizedBox(
          height: widget.isDialog
              ? 24
              : MediaQuery.paddingOf(context).bottom + 96,
        ),
      ],
    );

    if (widget.isDialog) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: content,
      ),
    );
  }

  void _submit() {
    final token = _controller.text.trim();
    if (token.isNotEmpty) {
      Navigator.pop(context, token);
    }
  }
}
