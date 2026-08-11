import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/selected_issue_provider.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Anchored project selector for the root issue feed.
///
/// The menu always starts at its first project directly below the field, so a
/// selected project never controls the popup's position or initial scroll.
class TodosProjectSwitcher extends ConsumerWidget {
  static const selectKey = ValueKey('todos-project-switcher-select');

  const TodosProjectSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = List<Project>.of(ref.watch(projectListProvider))
      ..sort(_compareProjects);
    final selectedId = ref.watch(selectedProjectProvider).asData?.value;

    if (projects.isEmpty) return const SizedBox.shrink();

    // Project-list changes can briefly race the persisted selection. Use the
    // first available project until the selected-project provider resolves.
    final selectedProject = projects.firstWhere(
      (project) => project.id == selectedId,
      orElse: () => projects.first,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final titleStyle = resolveTextStyle(
      context,
      TextTokens.body.$medium,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w600);
    final ownerStyle = resolveTextStyle(
      context,
      TextTokens.body.$small,
    ).copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w500);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final menuMaxHeight = (MediaQuery.sizeOf(context).height * 0.5).clamp(
            160.0,
            360.0,
          );

          return MenuAnchor(
            crossAxisUnconstrained: false,
            useRootOverlay: true,
            alignmentOffset: const Offset(0, 4),
            style: MenuStyle(
              alignment: Alignment.bottomLeft,
              backgroundColor: WidgetStatePropertyAll(surfaceLowest),
              elevation: const WidgetStatePropertyAll(4),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              minimumSize: WidgetStatePropertyAll(
                Size(constraints.maxWidth, 0),
              ),
              maximumSize: WidgetStatePropertyAll(
                Size(constraints.maxWidth, menuMaxHeight),
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: withOpacity(outlineVariant, 0.18)),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(editorialRadiusMedium),
                ),
              ),
            ),
            menuChildren: [
              for (final project in projects)
                MenuItemButton(
                  key: ValueKey('todos-project-switcher-option-${project.id}'),
                  style: ButtonStyle(
                    alignment: Alignment.centerLeft,
                    minimumSize: WidgetStatePropertyAll(
                      Size.fromHeight(project.ownerLogin.isEmpty ? 48 : 64),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    overlayColor: WidgetStatePropertyAll(
                      withOpacity(surfaceLow, 0.72),
                    ),
                  ),
                  onPressed: () => _selectProject(
                    context,
                    ref,
                    selectedId: selectedId,
                    nextId: project.id,
                  ),
                  child: _ProjectLabel(
                    project: project,
                    titleStyle: titleStyle,
                    ownerStyle: ownerStyle,
                  ),
                ),
            ],
            builder: (context, controller, child) {
              return Semantics(
                button: true,
                label: 'Select project',
                child: InkWell(
                  key: selectKey,
                  borderRadius: BorderRadius.circular(editorialRadiusMedium),
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: surfaceLowest,
                      borderRadius: BorderRadius.circular(
                        editorialRadiusMedium,
                      ),
                      border: Border.all(
                        color: withOpacity(outlineVariant, 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProjectLabel(
                            project: selectedProject,
                            titleStyle: titleStyle,
                            ownerStyle: ownerStyle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.chevronsUpDown,
                          color: onSurface,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static int _compareProjects(Project left, Project right) {
    final owner = _compareText(left.ownerLogin, right.ownerLogin);
    if (owner != 0) return owner;

    final name = _compareText(left.name, right.name);
    if (name != 0) return name;

    return left.id.compareTo(right.id);
  }

  static int _compareText(String left, String right) =>
      left.toLowerCase().compareTo(right.toLowerCase());

  static void _selectProject(
    BuildContext context,
    WidgetRef ref, {
    required String? selectedId,
    required String nextId,
  }) {
    if (nextId == selectedId) return;
    ref.read(selectedIssueProvider.notifier).clear();
    unawaited(
      ref
          .read(selectedProjectProvider.notifier)
          .select(nextId, optimistic: true),
    );
    context.goNamed(
      AppRoutes.projectName,
      pathParameters: {AppRoutes.projectIdParam: nextId},
    );
  }
}

class _ProjectLabel extends StatelessWidget {
  final Project project;
  final TextStyle titleStyle;
  final TextStyle ownerStyle;

  const _ProjectLabel({
    required this.project,
    required this.titleStyle,
    required this.ownerStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (project.ownerLogin.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            project.ownerLogin,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ownerStyle,
          ),
        ],
      ],
    );
  }
}
