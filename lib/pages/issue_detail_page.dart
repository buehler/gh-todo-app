import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/issue_detail/edit_comment_sheet.dart';
import 'package:gh_todos/compositions/issue_detail/edit_issue_sheet.dart';
import 'package:gh_todos/compositions/issue_detail/issue_conversation_section.dart';
import 'package:gh_todos/compositions/issue_detail/issue_description_section.dart';
import 'package:gh_todos/compositions/issue_detail/issue_detail_menu.dart';
import 'package:gh_todos/compositions/issue_detail/issue_detail_top_bar.dart';
import 'package:gh_todos/compositions/issue_detail/issue_header_section.dart';
import 'package:gh_todos/compositions/issue_detail/issue_state_action.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/selected_issue_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen, push-routed detail view for a single GitHub issue.
///
/// Lives outside the [StatefulShellRoute], so it owns its own [Scaffold] and
/// replaces the shell's top bar with its own back-button header.
///
/// Page-local mutable state: the header reads from the route-extra
/// [IssueData] which we copy into `_issue` and patch after each successful
/// mutation (close/reopen, title/body edits, priority/due-date changes).
/// Description + comments continue to flow through `issueDetailsProvider`,
/// which the mutation layer invalidates on success.
class IssueDetailPage extends ConsumerStatefulWidget {
  static const pageKey = ValueKey('issue-detail-page');
  static const scrollKey = ValueKey('issue-detail-scroll');

  final String issueId;
  final IssueData issue;

  /// When `true`, the page renders without its own [Scaffold] and its back
  /// button clears [selectedIssueProvider] instead of calling `context.pop`.
  /// Used when the page is embedded in [TodosSplitView]'s right pane on
  /// wide layouts.
  final bool embedded;

  const IssueDetailPage({
    required this.issueId,
    required this.issue,
    this.embedded = false,
    super.key,
  });

  @override
  ConsumerState<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends ConsumerState<IssueDetailPage> {
  late IssueData _issue = widget.issue;

  /// Set while any mutation is in flight so the state-action button disables
  /// itself (prevents double-taps that would fire the same mutation twice).
  bool _stateActionBusy = false;

  String get _issueId => widget.issueId;

  // -------------------------------- Mutations ------------------------------

  Future<bool> _postComment(String body) async {
    final mutations = ref.read(issueMutationsProvider);
    try {
      await mutations.postComment(issueId: _issueId, body: body);
      return true;
    } catch (_) {
      _showError('Failed to post comment.');
      return false;
    }
  }

  Future<void> _editComment(IssueComment comment) async {
    final updated = await showEditCommentSheet(context, comment: comment);
    if (updated == null) return;
    final mutations = ref.read(issueMutationsProvider);
    try {
      await mutations.updateComment(
        issueId: _issueId,
        commentId: comment.id,
        body: updated,
      );
    } catch (_) {
      _showError('Failed to update comment.');
    }
  }

  Future<void> _toggleIssueState() async {
    final projectId = _issue.projectId;
    if (projectId == null) {
      _showError('Issue is not attached to a project.');
      return;
    }
    setState(() => _stateActionBusy = true);
    final mutations = ref.read(issueMutationsProvider);
    try {
      if (_issue.closed) {
        final result = await mutations.reopenIssue(
          projectId: projectId,
          issueId: _issueId,
        );
        if (!mounted) return;
        setState(() {
          _issue = _issue.copyWith(
            closed: result.closed,
            closedAt: null,
            updatedAt: result.updatedAt.isNotEmpty
                ? result.updatedAt
                : _issue.updatedAt,
          );
        });
      } else {
        final result = await mutations.closeIssue(
          projectId: projectId,
          issueId: _issueId,
        );
        if (!mounted) return;
        setState(() {
          _issue = _issue.copyWith(
            closed: result.closed,
            closedAt: result.closedAt,
            updatedAt: result.updatedAt.isNotEmpty
                ? result.updatedAt
                : _issue.updatedAt,
          );
        });
      }
    } catch (_) {
      _showError(
        _issue.closed
            ? 'Failed to re-open the issue.'
            : 'Failed to close the issue.',
      );
    } finally {
      if (mounted) setState(() => _stateActionBusy = false);
    }
  }

  Future<void> _editIssue() async {
    // Read the currently-loaded body so the sheet opens prefilled. If the
    // details haven't resolved yet, fall back to empty and let the sheet
    // still open — saving without touching the body won't dispatch the
    // updateIssue mutation (bodyChanged would be false).
    final detailsAsync = ref.read(issueDetailsProvider(_issueId));
    final initialBody = detailsAsync.asData?.value.description ?? '';

    final project = _resolveProject();

    final result = await showEditIssueSheet(
      context,
      issue: _issue,
      currentBody: initialBody,
      project: project,
    );
    if (result == null || !result.hasAnyChange) return;

    final projectId = _issue.projectId;
    final itemId = _issue.projectItemId;
    final mutations = ref.read(issueMutationsProvider);

    try {
      if (result.titleChanged || result.bodyChanged) {
        if (projectId == null) {
          _showError('Issue is not attached to a project.');
          return;
        }
        final updated = await mutations.updateIssueCore(
          projectId: projectId,
          issueId: _issueId,
          title: result.titleChanged ? result.title : null,
          body: result.bodyChanged ? result.body : null,
        );
        if (!mounted) return;
        final nextUpdatedAt = updated.updatedAt.isNotEmpty
            ? updated.updatedAt
            : _issue.updatedAt;
        setState(() {
          // Freezed's copyWith treats omitted args as "unchanged"; we only
          // pass `title` through when it actually changed so we never try to
          // set the non-nullable field to null.
          _issue = result.titleChanged
              ? _issue.copyWith(title: updated.title, updatedAt: nextUpdatedAt)
              : _issue.copyWith(updatedAt: nextUpdatedAt);
        });
      }

      if (result.dueDateChanged) {
        final fieldId = project?.dueDateFieldId;
        if (projectId == null || itemId == null || fieldId == null) {
          _showError('Due date field is not configured on this project.');
          return;
        }
        if (result.dueDateCleared) {
          await mutations.clearProjectItemField(
            projectId: projectId,
            itemId: itemId,
            fieldId: fieldId,
          );
          if (!mounted) return;
          setState(() => _issue = _issue.copyWith(dueDate: null));
        } else if (result.dueDate != null) {
          await mutations.setProjectItemDate(
            projectId: projectId,
            itemId: itemId,
            fieldId: fieldId,
            isoDate: result.dueDate!,
          );
          if (!mounted) return;
          setState(() => _issue = _issue.copyWith(dueDate: result.dueDate));
        }
      }

      if (result.priorityChanged) {
        final fieldId = project?.priorityFieldId;
        if (projectId == null || itemId == null || fieldId == null) {
          _showError('Priority field is not configured on this project.');
          return;
        }
        if (result.priorityCleared) {
          await mutations.clearProjectItemField(
            projectId: projectId,
            itemId: itemId,
            fieldId: fieldId,
          );
          if (!mounted) return;
          setState(() => _issue = _issue.copyWith(priority: null));
        } else if (result.priority != null) {
          final optionId = _resolveOptionId(project!, result.priority!);
          if (optionId == null) {
            _showError('Priority option is no longer mapped.');
            return;
          }
          await mutations.setProjectItemSingleSelect(
            projectId: projectId,
            itemId: itemId,
            fieldId: fieldId,
            optionId: optionId,
          );
          if (!mounted) return;
          setState(() => _issue = _issue.copyWith(priority: result.priority));
        }
      }
    } catch (_) {
      _showError('Failed to update the issue.');
    }
  }

  // -------------------------------- Helpers --------------------------------

  Project? _resolveProject() {
    final projectId = _issue.projectId;
    if (projectId == null) return null;
    final projects = ref.read(projectListProvider);
    for (final p in projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }

  String? _resolveOptionId(Project project, TodoPriority priority) {
    for (final entry in project.priorityOptionMap.entries) {
      if (entry.value == priority) return entry.key;
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------- UI -----------------------------------

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    // Leave a bit of breathing room below the composer for the safe-area
    // (home-indicator) and the on-screen keyboard's clearance.
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 32;

    final viewerLogin = ref.watch(userInfoProvider).asData?.value?.login;

    // In embedded mode the outer AppTopBar already fills the top-edge space
    // (and is rendered *above* the pane in the shell's Stack, so we can't put
    // our own top bar there). The inline toolbar sits just below it, giving
    // Edit / Open-in-GitHub / Close the desktop-grade visibility a kebab
    // would hide.
    final contentTopPadding = widget.embedded
        ? 16.0
        : IssueDetailTopBar.barHeight + safeTop + 24;

    final content = SingleChildScrollView(
      key: IssueDetailPage.scrollKey,
      padding: EdgeInsets.only(
        top: contentTopPadding,
        left: 24,
        right: 24,
        bottom: bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          // Reading-column clamp keeps issue descriptions and conversation
          // threads comfortable even on ultra-wide windows.
          constraints: const BoxConstraints(maxWidth: 720),
          child: ColumnBox(
            style: FlexBoxStyler().flex(
              FlexStyler()
                  .direction(Axis.vertical)
                  .crossAxisAlignment(CrossAxisAlignment.stretch)
                  .mainAxisSize(MainAxisSize.min)
                  .spacing(32),
            ),
            children: [
              IssueHeaderSection(issue: _issue),
              IssueStateAction(
                issue: _issue,
                enabled: !_stateActionBusy,
                onPressed: _stateActionBusy
                    ? null
                    : () => unawaited(_toggleIssueState()),
              ),
              IssueDescriptionSection(issueId: _issueId),
              IssueConversationSection(
                issueId: _issueId,
                commentCount: _issue.commentCount,
                viewerLogin: viewerLogin,
                onPostComment: _postComment,
                onEditComment: (c) => unawaited(_editComment(c)),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      // The shell hides AppTopBar on wide, so we only reserve the safe-area
      // inset. The inline toolbar provides the pane's top chrome directly.
      return Column(
        children: [
          SizedBox(height: AppTopBar.effectiveHeight(context) + safeTop),
          _EmbeddedDetailToolbar(
            onEdit: () => unawaited(_editIssue()),
            onOpenInBrowser: () => unawaited(_openInBrowser()),
            onClose: _handleBack,
          ),
          Expanded(child: content),
        ],
      );
    }

    final stack = Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IssueDetailTopBar(
            onBack: _handleBack,
            onMenuAction: _handleMenuAction,
          ),
        ),
      ],
    );

    return Scaffold(
      key: IssueDetailPage.pageKey,
      backgroundColor: resolveColor(context, ColorTokens.background.$default),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: stack,
    );
  }

  void _handleBack() {
    if (widget.embedded) {
      // Detail pane owns the selected-issue state on wide.
      ref.read(selectedIssueProvider.notifier).clear();
      return;
    }
    context.pop();
  }

  void _handleMenuAction(IssueDetailMenuAction action) {
    switch (action) {
      case IssueDetailMenuAction.editIssue:
        unawaited(_editIssue());
        break;
      case IssueDetailMenuAction.openInBrowser:
        unawaited(_openInBrowser());
        break;
    }
  }

  /// Launches the issue's canonical GitHub URL in the system browser.
  ///
  /// The URL is fetched lazily via `issueDetailsProvider`; if it hasn't
  /// resolved yet (menu tapped before the detail payload lands), await the
  /// future so the action doesn't silently no-op. Failures are swallowed — the
  /// user can always retry.
  Future<void> _openInBrowser() async {
    final String? url;
    try {
      final details = await ref.read(issueDetailsProvider(_issueId).future);
      url = details.url;
    } catch (_) {
      return;
    }
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Desktop-style inline action row for the embedded (split-view) detail
/// pane.
///
/// Replaces the mobile `IssueDetailTopBar`'s kebab menu — icons are always
/// visible, labeled via tooltips, and grouped on the right. Less "mobile-y"
/// than a hidden overflow menu and gives the detail pane a clear "close"
/// affordance (which otherwise only exists via tapping another row).
class _EmbeddedDetailToolbar extends StatelessWidget {
  static const editKey = ValueKey('issue-detail-embedded-edit');
  static const openInBrowserKey = ValueKey(
    'issue-detail-embedded-open-in-browser',
  );
  static const closeKey = ValueKey('issue-detail-embedded-close');

  final VoidCallback onEdit;
  final VoidCallback onOpenInBrowser;
  final VoidCallback onClose;

  const _EmbeddedDetailToolbar({
    required this.onEdit,
    required this.onOpenInBrowser,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          EditorialIconButton(
            key: editKey,
            icon: LucideIcons.pencil,
            tooltip: 'Edit issue',
            variation: IconButtonVariation.ghost,
            size: 40,
            onPressed: onEdit,
          ),
          const SizedBox(width: 4),
          EditorialIconButton(
            key: openInBrowserKey,
            icon: LucideIcons.externalLink,
            tooltip: 'Open in GitHub',
            variation: IconButtonVariation.ghost,
            size: 40,
            onPressed: onOpenInBrowser,
          ),
          const SizedBox(width: 4),
          EditorialIconButton(
            key: closeKey,
            icon: LucideIcons.x,
            tooltip: 'Close detail',
            variation: IconButtonVariation.ghost,
            size: 40,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
