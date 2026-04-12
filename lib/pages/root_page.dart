import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/compositions/todos/todos_fab.dart';
import 'package:gh_todos/compositions/todos/todos_group_header.dart';
import 'package:gh_todos/compositions/todos/todos_hero.dart';
import 'package:gh_todos/compositions/todos/todos_issue_grid.dart';
import 'package:gh_todos/compositions/todos/todos_project_chips.dart';
import 'package:gh_todos/services/mock_todos_data.dart';
import 'package:mix/mix.dart';

/// The authenticated root page — the "Issues" feed.
///
/// Renders a hero greeting, a horizontal project chip selector and a
/// grouped grid of issue cards. Hosted inside the app shell, so the top
/// bar and bottom nav are provided by [AppShell] rather than by this widget.
/// A floating action button is overlaid via a [Stack].
class RootPage extends StatelessWidget {
  static const pageKey = ValueKey('root-page');
  static const scrollKey = ValueKey('root-page-scroll');

  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = AppTopBar.barHeight + MediaQuery.paddingOf(context).top;
    final bottomPadding =
        AppBottomNav.barHeight + MediaQuery.paddingOf(context).bottom + 120;

    return Stack(
      key: pageKey,
      children: [
        SingleChildScrollView(
          key: scrollKey,
          padding: EdgeInsets.only(
            top: topPadding + 24,
            bottom: bottomPadding,
          ),
          child: ColumnBox(
            style: editorialColumnStyle(
              spacing: 28,
              crossAxis: CrossAxisAlignment.start,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TodosHero(),
              ),
              const TodosProjectChips(),
              for (final group in mockTodoGroups)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ColumnBox(
                    style: editorialColumnStyle(
                      spacing: 16,
                      crossAxis: CrossAxisAlignment.start,
                    ).width(double.infinity),
                    children: [
                      TodosGroupHeader(group: group),
                      TodosIssueGrid(group: group),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: AppBottomNav.barHeight +
              MediaQuery.paddingOf(context).bottom +
              24,
          child: TodosFab(onPressed: () {}),
        ),
      ],
    );
  }
}
