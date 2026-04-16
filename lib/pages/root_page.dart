import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/editorial_icon_button.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/compositions/todos/swipeable_issue_row.dart';
import 'package:gh_todos/compositions/todos/todos_issue_composer.dart';
import 'package:gh_todos/compositions/todos/todos_project_chips.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/selected_issue_provider.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// The authenticated root page — the "Issues" feed.
///
/// Shows project chips for switching, an inline quick-add composer, and a
/// list of issues for the currently selected project. Supports pull-to-refresh.
class RootPage extends ConsumerWidget {
  static const pageKey = ValueKey('root-page');
  static const scrollKey = ValueKey('root-page-scroll');
  static const emptyKey = ValueKey('root-page-empty');
  static const recentlyClosedHeaderKey = ValueKey('root-page-closed-header');
  static const refreshButtonKey = ValueKey('root-page-refresh-button');
  static const refreshProgressKey = ValueKey('root-page-refresh-progress');

  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding =
        AppTopBar.effectiveHeight(context) + MediaQuery.paddingOf(context).top;
    // On wide, the bottom nav is replaced by the side rail — skip its height.
    final bottomPadding =
        (isWide(context) ? 0 : AppBottomNav.barHeight) +
        MediaQuery.paddingOf(context).bottom +
        32;
    final selectedId = ref.watch(selectedProjectProvider);

    if (selectedId == null) {
      return _EmptyState(key: pageKey, topPadding: topPadding);
    }

    return _IssuesFeed(
      key: pageKey,
      projectId: selectedId,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double topPadding;

  const _EmptyState({super.key, required this.topPadding});

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

class _IssuesFeed extends ConsumerStatefulWidget {
  final String projectId;
  final double topPadding;
  final double bottomPadding;

  const _IssuesFeed({
    super.key,
    required this.projectId,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  ConsumerState<_IssuesFeed> createState() => _IssuesFeedState();
}

class _IssuesFeedState extends ConsumerState<_IssuesFeed> {
  bool _isRefreshing = false;

  bool get _supportsPullToRefresh {
    if (kIsWeb) return false;

    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.android => true,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => false,
    };
  }

  Future<void> _refreshIssues() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _refreshProjectIssues(ref, widget.projectId);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(projectIssuesProvider(widget.projectId));

    final scrollView = CustomScrollView(
      key: RootPage.scrollKey,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: widget.topPadding + 24),
            child: _FeedHeader(
              showManualRefresh: !_supportsPullToRefresh,
              isRefreshing: _isRefreshing,
              onRefresh: _refreshIssues,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 20, bottom: 28),
            child: TodosIssueComposer(),
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
                    color: resolveColor(context, ColorTokens.surface.onVariant),
                  ),
                ),
              ),
            ),
          ],
          data: (feed) => _dataSlivers(
            context,
            feed,
            projectId: widget.projectId,
            bottomPadding: widget.bottomPadding,
          ),
        ),
      ],
    );

    final feed = _supportsPullToRefresh
        ? RefreshIndicator(
            onRefresh: _refreshIssues,
            edgeOffset: widget.topPadding + 24,
            child: scrollView,
          )
        : scrollView;

    // On wide layouts the list pane lives inside TodosSplitView's flex-4
    // column — still enforce a reading-column clamp so even an ultra-wide
    // window keeps issue rows comfortable to scan.
    if (isWide(context)) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: feed,
        ),
      );
    }
    return feed;
  }
}

class _FeedHeader extends StatelessWidget {
  final bool showManualRefresh;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _FeedHeader({
    required this.showManualRefresh,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return Row(
      children: [
        const Expanded(child: TodosProjectChips()),
        if (showManualRefresh) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: isRefreshing
                  ? Box(
                      style: BoxStyler()
                          .color(surfaceLow)
                          .borderRounded(editorialRadiusMedium)
                          .alignment(Alignment.center),
                      child: SizedBox(
                        key: RootPage.refreshProgressKey,
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(onSurfaceVariant),
                        ),
                      ),
                    )
                  : EditorialIconButton(
                      key: RootPage.refreshButtonKey,
                      icon: LucideIcons.refreshCw,
                      tooltip: 'Refresh issues',
                      variation: IconButtonVariation.tonal,
                      enabled: !isRefreshing,
                      onPressed: onRefresh,
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _refreshProjectIssues(WidgetRef ref, String projectId) async {
  ref.invalidate(projectIssuesProvider(projectId));
  await ref.read(projectIssuesProvider(projectId).future);
}

List<Widget> _dataSlivers(
  BuildContext context,
  ProjectIssuesFeed feed, {
  required String projectId,
  required double bottomPadding,
}) {
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
          // bottom for the nav bar.
          bottom: closed.isEmpty ? bottomPadding : 0,
        ),
        sliver: _IssueSliverList(issues: open, projectId: projectId),
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
        padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding),
        sliver: _IssueSliverList(issues: closed, projectId: projectId),
      ),
    );
  }

  return slivers;
}

class _IssueSliverList extends ConsumerWidget {
  final List<IssueData> issues;
  final String projectId;

  const _IssueSliverList({required this.issues, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList.separated(
      itemCount: issues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final issue = issues[index];
        return SwipeableIssueRow(
          issue: issue,
          projectId: projectId,
          onTap: () => _openIssue(context, ref, issue),
        );
      },
    );
  }
}

/// Opens an issue. On wide layouts (`≥ 900px`) this stays in-shell by
/// setting [selectedIssueProvider] — [TodosSplitView] then fills the detail
/// pane. On compact/medium widths it pushes the full-screen
/// [IssueDetailPage] route as before.
void _openIssue(BuildContext context, WidgetRef ref, IssueData issue) {
  if (isWide(context)) {
    ref.read(selectedIssueProvider.notifier).select(issue);
    return;
  }
  context.pushNamed(
    AppRoutes.issueDetailName,
    pathParameters: {'id': issue.id},
    extra: issue,
  );
}
