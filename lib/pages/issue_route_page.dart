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
  final IssueData? initialIssue;
  final List<String> failedFields;

  const IssueRoutePage({
    required this.requestedProjectId,
    required this.issueId,
    this.routeRefreshKey,
    this.initialIssue,
    this.failedFields = const [],
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
          initialIssue: initialIssue,
          failedFields: failedFields,
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
      initialIssue: initialIssue,
      failedFields: failedFields,
      embedded: false,
    );
  }
}

class _IssueRouteDetail extends ConsumerStatefulWidget {
  final String requestedProjectId;
  final String issueId;
  final String? routeRefreshKey;
  final IssueData? initialIssue;
  final List<String> failedFields;
  final bool embedded;

  const _IssueRouteDetail({
    required this.requestedProjectId,
    required this.issueId,
    required this.routeRefreshKey,
    required this.initialIssue,
    required this.failedFields,
    required this.embedded,
  });

  @override
  ConsumerState<_IssueRouteDetail> createState() => _IssueRouteDetailState();
}

class _IssueRouteDetailState extends ConsumerState<_IssueRouteDetail> {
  @override
  void initState() {
    super.initState();
    if (widget.failedFields.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Todo created. Could not save ${widget.failedFields.join(' and ')}. '
              'Edit the todo to set it.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      });
    }
  }

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

        if (widget.requestedProjectId.trim() == projectId &&
            ref.read(selectedProjectProvider).asData?.value != projectId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              ref
                  .read(selectedProjectProvider.notifier)
                  .select(projectId, optimistic: true),
            );
          });
        }

        final initial = widget.initialIssue;
        if (initial != null &&
            initial.id == widget.issueId &&
            initial.projectId == projectId) {
          return _detail(context, projectId, initial);
        }

        final feedAsync = switch (widget.routeRefreshKey) {
          final refreshKey? => ref.watch(
            projectRouteRefreshProvider((
              projectId: projectId,
              refreshKey: refreshKey,
            )),
          ),
          null => ref.watch(projectIssuesProvider(projectId)),
        };
        return _buildIssue(context, projectId, feedAsync);
      },
    );
  }

  Widget _buildIssue(
    BuildContext context,
    String projectId,
    AsyncValue<ProjectIssuesFeed> feedAsync,
  ) {
    if (feedAsync.isLoading) return _frame(const _RouteLoading());
    final feed = feedAsync.asData?.value;
    final inFeed = feed == null ? null : _findIssue(feed, widget.issueId);
    if (inFeed != null) return _detail(context, projectId, inFeed);

    final directAsync = ref.watch(
      projectIssueByIdProvider((projectId: projectId, issueId: widget.issueId)),
    );
    return directAsync.when(
      loading: () => _frame(const _RouteLoading()),
      error: (_, _) => _frame(const _RouteMessage('Failed to load issue.')),
      data: (issue) => issue == null
          ? _RouteRedirect(location: AppRoutes.projectLocation(projectId))
          : _detail(context, projectId, issue),
    );
  }

  Widget _detail(BuildContext context, String projectId, IssueData issue) {
    return IssueDetailPage(
      key: ValueKey('issue-route-$projectId-${widget.issueId}'),
      issueId: widget.issueId,
      issue: issue,
      embedded: widget.embedded,
      onBack: () {
        if (!widget.embedded && context.canPop()) {
          context.pop();
        } else {
          context.goNamed(
            AppRoutes.projectName,
            pathParameters: {AppRoutes.projectIdParam: projectId},
          );
        }
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
