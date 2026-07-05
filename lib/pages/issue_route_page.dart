import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/compositions/shell/todos_split_view.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/pages/issue_detail_page.dart';
import 'package:gh_todos/pages/root_page.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:go_router/go_router.dart';

class IssueRoutePage extends ConsumerWidget {
  final String requestedProjectId;
  final String issueId;
  final String? routeRefreshKey;

  const IssueRoutePage({
    required this.requestedProjectId,
    required this.issueId,
    this.routeRefreshKey,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isWide(context)) {
      return TodosSplitView(
        detail: _IssueRouteDetail(
          requestedProjectId: requestedProjectId,
          issueId: issueId,
          routeRefreshKey: routeRefreshKey,
          embedded: true,
        ),
        child: RootPage(
          requestedProjectId: requestedProjectId,
          routeRefreshKey: routeRefreshKey,
        ),
      );
    }

    return _IssueRouteDetail(
      requestedProjectId: requestedProjectId,
      issueId: issueId,
      routeRefreshKey: routeRefreshKey,
      embedded: false,
    );
  }
}

class _IssueRouteDetail extends ConsumerStatefulWidget {
  final String requestedProjectId;
  final String issueId;
  final String? routeRefreshKey;
  final bool embedded;

  const _IssueRouteDetail({
    required this.requestedProjectId,
    required this.issueId,
    required this.routeRefreshKey,
    required this.embedded,
  });

  @override
  ConsumerState<_IssueRouteDetail> createState() => _IssueRouteDetailState();
}

class _IssueRouteDetailState extends ConsumerState<_IssueRouteDetail> {
  String? _activeRouteRefreshKey;
  Future<ProjectIssuesFeed>? _routeRefreshFuture;

  @override
  Widget build(BuildContext context) {
    final projectIdAsync = ref.watch(
      routeSelectedProjectProvider(widget.requestedProjectId),
    );

    return projectIdAsync.when(
      loading: () => _frame(const _RouteLoading()),
      error: (_, _) => _frame(const _RouteMessage('Failed to load project.')),
      data: (projectId) {
        if (projectId == null) {
          return const _RouteRedirect(location: AppRoutes.rootPath);
        }

        if (widget.routeRefreshKey != null) {
          return FutureBuilder<ProjectIssuesFeed>(
            future: _freshRouteFuture(projectId),
            builder: (context, snapshot) {
              final AsyncValue<ProjectIssuesFeed> feedAsync = switch (snapshot
                  .connectionState) {
                ConnectionState.done when snapshot.hasError => AsyncValue.error(
                  snapshot.error!,
                  snapshot.stackTrace ?? StackTrace.current,
                ),
                ConnectionState.done => AsyncValue.data(snapshot.requireData),
                _ => const AsyncValue<ProjectIssuesFeed>.loading(),
              };
              return _buildIssue(context, projectId, feedAsync);
            },
          );
        }

        return _buildIssue(
          context,
          projectId,
          ref.watch(projectIssuesProvider(projectId)),
        );
      },
    );
  }

  Future<ProjectIssuesFeed> _freshRouteFuture(String projectId) {
    final routeKey = '$projectId:${widget.routeRefreshKey}';
    if (_activeRouteRefreshKey != routeKey) {
      _activeRouteRefreshKey = routeKey;
      _routeRefreshFuture = Future<void>.delayed(
        Duration.zero,
      ).then((_) => refreshProjectIssuesForRoute(ref, projectId));
    }
    return _routeRefreshFuture!;
  }

  Widget _buildIssue(
    BuildContext context,
    String projectId,
    AsyncValue<ProjectIssuesFeed> feedAsync,
  ) {
    return feedAsync.when(
      loading: () => _frame(const _RouteLoading()),
      error: (_, _) => _frame(const _RouteMessage('Failed to load issue.')),
      data: (feed) {
        final issue = _findIssue(feed, widget.issueId);
        if (issue == null) {
          return _RouteRedirect(location: AppRoutes.projectLocation(projectId));
        }

        return IssueDetailPage(
          key: ValueKey('issue-route-$projectId-${widget.issueId}'),
          issueId: widget.issueId,
          issue: issue,
          embedded: widget.embedded,
          onBack: widget.embedded
              ? () => context.goNamed(
                  AppRoutes.projectName,
                  pathParameters: {AppRoutes.projectIdParam: projectId},
                )
              : null,
        );
      },
    );
  }

  Widget _frame(Widget child) {
    if (widget.embedded) return child;
    return Scaffold(body: child);
  }
}

IssueData? _findIssue(ProjectIssuesFeed feed, String issueId) {
  for (final issue in feed.open) {
    if (issue.id == issueId) return issue;
  }
  for (final issue in feed.closed) {
    if (issue.id == issueId) return issue;
  }
  return null;
}

class _RouteRedirect extends StatelessWidget {
  final String location;

  const _RouteRedirect({required this.location});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(location);
    });
    return const SizedBox.shrink();
  }
}

class _RouteLoading extends StatelessWidget {
  const _RouteLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _RouteMessage extends StatelessWidget {
  final String message;

  const _RouteMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
