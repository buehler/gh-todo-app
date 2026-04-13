import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/compositions/todos/todos_fab.dart';
import 'package:gh_todos/compositions/todos/todos_hero.dart';
import 'package:gh_todos/compositions/todos/todos_issue_card.dart';
import 'package:gh_todos/compositions/todos/todos_project_chips.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// The authenticated root page — the "Issues" feed.
///
/// Shows a greeting, project chips for switching, and a list of issues
/// for the currently selected project. Supports pull-to-refresh.
class RootPage extends ConsumerWidget {
  static const pageKey = ValueKey('root-page');
  static const scrollKey = ValueKey('root-page-scroll');
  static const emptyKey = ValueKey('root-page-empty');

  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = AppTopBar.barHeight + MediaQuery.paddingOf(context).top;
    final bottomPadding =
        AppBottomNav.barHeight + MediaQuery.paddingOf(context).bottom + 120;
    final selectedId = ref.watch(selectedProjectProvider);

    return Stack(
      key: pageKey,
      children: [
        if (selectedId == null)
          _EmptyState(topPadding: topPadding)
        else
          _IssuesFeed(
            projectId: selectedId,
            topPadding: topPadding,
            bottomPadding: bottomPadding,
          ),
        Positioned(
          right: 24,
          bottom:
              AppBottomNav.barHeight +
              MediaQuery.paddingOf(context).bottom +
              24,
          child: TodosFab(onPressed: () {}),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double topPadding;

  const _EmptyState({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return Center(
      key: RootPage.emptyKey,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: StyledText(
          'Add a project in Settings to get started.',
          style: editorialTextStyle(
            TextTokens.body.$large,
            color: onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _IssuesFeed extends ConsumerWidget {
  final String projectId;
  final double topPadding;
  final double bottomPadding;

  const _IssuesFeed({
    required this.projectId,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(projectIssuesProvider(projectId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectIssuesProvider(projectId));
        // Wait for the provider to complete after invalidation.
        await ref.read(projectIssuesProvider(projectId).future);
      },
      edgeOffset: topPadding + 24,
      child: CustomScrollView(
        key: RootPage.scrollKey,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 24,
                left: 24,
                right: 24,
              ),
              child: const TodosHero(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 20, bottom: 28),
              child: TodosProjectChips(),
            ),
          ),
          issuesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SliverFillRemaining(
              child: Center(
                child: StyledText(
                  'Failed to load issues.',
                  style: editorialTextStyle(
                    TextTokens.body.$large,
                    color: resolveColor(
                      context,
                      ColorTokens.surface.onVariant,
                    ),
                  ),
                ),
              ),
            ),
            data: (issues) {
              if (issues.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: StyledText(
                      'No open issues assigned to you.',
                      style: editorialTextStyle(
                        TextTokens.body.$large,
                        color: resolveColor(
                          context,
                          ColorTokens.surface.onVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: bottomPadding,
                ),
                sliver: SliverList.separated(
                  itemCount: issues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, index) =>
                      TodosIssueCard(issue: issues[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
