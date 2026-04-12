import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/services/mock_todos_data.dart';

/// Horizontally-scrollable filter chips representing the user's projects.
///
/// Uses mock data for now. Selection is purely cosmetic — the first chip is
/// pre-selected and tapping others does nothing yet.
class TodosProjectChips extends StatelessWidget {
  static const pageKey = ValueKey('todos-project-chips');

  const TodosProjectChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: pageKey,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < mockTodoProjects.length; i++) ...[
            EditorialChip(
              label: mockTodoProjects[i].label,
              selected: i == 0,
              onPressed: () {},
            ),
            if (i < mockTodoProjects.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
