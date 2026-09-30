import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shell/todos_split_view.dart';
import 'package:gh_todos/compositions/todos/new_todo_form.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:mix/mix.dart';

class NewTodoRoutePage extends ConsumerWidget {
  final String requestedProjectId;
  final String? routeRefreshKey;

  const NewTodoRoutePage({
    required this.requestedProjectId,
    this.routeRefreshKey,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref
        .watch(projectListProvider)
        .where((p) => p.id == requestedProjectId)
        .firstOrNull;
    if (project == null) {
      return Scaffold(
        backgroundColor: resolveColor(context, ColorTokens.surface.$default),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StyledText(
                  'This project is unavailable.',
                  style: editorialTextStyle(
                    TextTokens.body.$large,
                    color: resolveColor(context, ColorTokens.surface.onVariant),
                  ),
                ),
                const SizedBox(height: 16),
                EditorialButton(
                  label: 'Back to projects',
                  onPressed: () => context.goNamed(AppRoutes.rootName),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final form = NewTodoForm(
      key: ValueKey('new-todo-form-${project.id}'),
      project: project,
      embedded: isWide(context),
    );
    if (!isWide(context)) return form;

    return TodosSplitView(
      detail: form,
      child: RootPage(
        requestedProjectId: project.id,
        routeRefreshKey: routeRefreshKey,
        showNewTodoAction: false,
      ),
    );
  }
}
