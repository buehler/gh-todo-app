import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

enum EditProjectAction { remove }

/// Shows a bottom sheet with actions for a mapped project.
///
/// Currently only supports [EditProjectAction.remove].
Future<EditProjectAction?> showEditProjectSheet(
  BuildContext context,
  Project project,
) {
  return showModalBottomSheet<EditProjectAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditProjectSheet(project: project),
  );
}

class _EditProjectSheet extends StatelessWidget {
  final Project project;

  const _EditProjectSheet({required this.project});

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
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);
    final error = resolveColor(context, ColorTokens.error.$default);
    final errorContainer = resolveColor(context, ColorTokens.error.container);
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );

    return Container(
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: withOpacity(outlineVariant, 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Project info
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: ColumnBox(
              style: editorialColumnStyle(
                spacing: 2,
                crossAxis: CrossAxisAlignment.start,
              ),
              children: [
                StyledText(
                  project.name,
                  style: editorialTextStyle(
                    TextTokens.title.$large,
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (project.ownerLogin.isNotEmpty)
                  StyledText(
                    project.ownerLogin,
                    style: editorialTextStyle(
                      TextTokens.body.$medium,
                      color: onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Remove action
          PressableBox(
            onPress: () =>
                Navigator.pop(context, EditProjectAction.remove),
            style: BoxStyler()
                .color(Colors.transparent)
                .paddingOnly(horizontal: 24, vertical: 16)
                .animate(editorialAnimation)
                .onHovered(BoxStyler().color(surfaceHighest)),
            child: RowBox(
              style: editorialRowStyle(spacing: 16, mainAxisSize: MainAxisSize.max),
              children: [
                Box(
                  style: BoxStyler()
                      .width(40)
                      .height(40)
                      .color(withOpacity(errorContainer, 0.3))
                      .borderRounded(editorialRadiusSmall)
                      .alignment(Alignment.center),
                  child: StyledIcon(
                    icon: LucideIcons.trash2,
                    style: editorialIconStyle(color: error, size: 20),
                  ),
                ),
                Expanded(
                  child: StyledText(
                    'Remove Project',
                    style: editorialTextStyle(
                      TextTokens.body.$medium,
                      color: error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 96),
        ],
      ),
    );
  }
}
