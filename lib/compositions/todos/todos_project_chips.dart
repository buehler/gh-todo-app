import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/selected_issue_provider.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';

/// Horizontally-scrollable filter chips for switching between mapped projects.
///
/// Selection is persisted via [selectedProjectProvider].
class TodosProjectChips extends ConsumerWidget {
  static const pageKey = ValueKey('todos-project-chips');

  const TodosProjectChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final selectedId = ref.watch(selectedProjectProvider).asData?.value;

    if (projects.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: pageKey,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < projects.length; i++) ...[
            EditorialChip(
              label: projects[i].name,
              selected: projects[i].id == selectedId,
              onPressed: () {
                final nextId = projects[i].id;
                if (nextId == selectedId) return;
                ref.read(selectedIssueProvider.notifier).clear();
                ref.read(selectedProjectProvider.notifier).select(nextId);
              },
            ),
            if (i < projects.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
