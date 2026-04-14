import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/compositions/todos/todos_fab.dart';
import 'package:gh_todos/compositions/todos/todos_hero.dart';
import 'package:gh_todos/compositions/todos/todos_issue_card.dart';
import 'package:gh_todos/compositions/todos/todos_project_chips.dart';
import 'package:gh_todos/models/issue_data.dart';
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
  static const recentlyClosedHeaderKey = ValueKey('root-page-closed-header');

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
    final feedAsync = ref.watch(projectIssuesProvider(projectId));

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
          ...feedAsync.when(
            loading: () => [
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (_, _) => [
              SliverFillRemaining(
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
            ],
            data: (feed) => _dataSlivers(context, feed, bottomPadding),
          ),
        ],
      ),
    );
  }
}

List<Widget> _dataSlivers(
  BuildContext context,
  ProjectIssuesFeed feed,
  double bottomPadding,
) {
  final open = feed.open;
  final closed = feed.closed;

  if (open.isEmpty && closed.isEmpty) {
    return [
      SliverFillRemaining(
        child: Center(
          child: StyledText(
            'No open issues assigned to you.',
            style: editorialTextStyle(
              TextTokens.body.$large,
              color: resolveColor(context, ColorTokens.surface.onVariant),
            ),
          ),
        ),
      ),
    ];
  }

  final slivers = <Widget>[];

  if (open.isNotEmpty) {
    slivers.add(
      SliverPadding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          // Leave room below only when closed section follows; otherwise pad to
          // bottom for the FAB + nav.
          bottom: closed.isEmpty ? bottomPadding : 0,
        ),
        sliver: _IssueSliverList(issues: open),
      ),
    );
  } else {
    // Only closed issues exist — give the closed section a minimal header
    // context with a short note above it.
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: StyledText(
            'No open issues.',
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: resolveColor(context, ColorTokens.surface.onVariant),
            ),
          ),
        ),
      ),
    );
  }

  if (closed.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        key: RootPage.recentlyClosedHeaderKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: StyledText(
            'Recently closed',
            style: editorialTextStyle(
              TextTokens.label.$small,
              color: resolveColor(context, ColorTokens.primary.$default),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
    slivers.add(
      SliverPadding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: bottomPadding,
        ),
        sliver: _IssueSliverList(issues: closed),
      ),
    );
  }

  return slivers;
}

class _IssueSliverList extends StatelessWidget {
  final List<IssueData> issues;

  const _IssueSliverList({required this.issues});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: issues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, index) => TodosIssueCard(issue: issues[index]),
    );
  }
}
