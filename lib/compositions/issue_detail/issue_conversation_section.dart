import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class IssueConversationSection extends ConsumerWidget {
  static const pageKey = ValueKey('issue-conversation-section');
  static const commentListKey = ValueKey('issue-conversation-list');

  final String issueId;
  final int commentCount;
  final void Function(IssueComment comment)? onEditComment;
  final void Function(IssueComment comment)? onHideComment;
  final void Function(IssueComment comment)? onUnhideComment;
  final void Function(IssueComment comment)? onDeleteComment;
  final Future<void> Function(
    IssueComment comment,
    int taskIndex,
    bool checked,
  )?
  onTaskToggle;
  final Set<String> taskToggleBusyCommentIds;

  const IssueConversationSection({
    required this.issueId,
    required this.commentCount,
    this.onEditComment,
    this.onHideComment,
    this.onUnhideComment,
    this.onDeleteComment,
    this.onTaskToggle,
    this.taskToggleBusyCommentIds = const {},
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onVariant = resolveColor(context, ColorTokens.surface.onVariant);
    final commentsAsync = ref.watch(issueCommentsProvider(issueId));
    final isOffline = ref.watch(offlineStatusProvider).asData?.value ?? false;
    final liveCount = commentsAsync.asData?.value.length ?? commentCount;
    return ColumnBox(
      key: pageKey,
      style: editorialColumnStyle(
        spacing: 16,
        crossAxis: CrossAxisAlignment.start,
      ),
      children: [
        Row(
          children: [
            StyledText(
              'Conversation',
              style: editorialTextStyle(
                TextTokens.title.$large,
                color: onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 12),
            if (liveCount > 0)
              Box(
                style: BoxStyler()
                    .color(
                      resolveColor(context, ColorTokens.surface.containerHigh),
                    )
                    .borderRounded(999)
                    .paddingOnly(horizontal: 10, vertical: 4),
                child: StyledText(
                  '$liveCount',
                  style: editorialTextStyle(
                    TextTokens.label.$medium,
                    color: onVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => StyledText(
            isOffline
                ? 'Offline. Conversation is unavailable until this issue has been loaded once.'
                : 'Failed to load conversation.',
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: onVariant,
            ),
          ),
          data: (comments) => _CommentList(
            comments: comments,
            onEdit: onEditComment,
            onHide: onHideComment,
            onUnhide: onUnhideComment,
            onDelete: onDeleteComment,
            onTaskToggle: onTaskToggle,
            taskToggleBusyIds: taskToggleBusyCommentIds,
          ),
        ),
      ],
    );
  }
}

class _CommentList extends StatefulWidget {
  final List<IssueComment> comments;
  final void Function(IssueComment)? onEdit;
  final void Function(IssueComment)? onHide;
  final void Function(IssueComment)? onUnhide;
  final void Function(IssueComment)? onDelete;
  final Future<void> Function(IssueComment, int, bool)? onTaskToggle;
  final Set<String> taskToggleBusyIds;
  const _CommentList({
    required this.comments,
    this.onEdit,
    this.onHide,
    this.onUnhide,
    this.onDelete,
    this.onTaskToggle,
    required this.taskToggleBusyIds,
  });

  @override
  State<_CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<_CommentList> {
  final Set<String> _shownMinimizedCommentIds = <String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.comments.isEmpty) {
      return StyledText(
        'No comments yet.',
        style: editorialTextStyle(
          TextTokens.body.$medium,
          color: withOpacity(
            resolveColor(context, ColorTokens.surface.onVariant),
            0.7,
          ),
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return Column(
      key: IssueConversationSection.commentListKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final comment in widget.comments) ...[
          _CommentCard(
            comment: comment,
            expandedMinimized: _shownMinimizedCommentIds.contains(comment.id),
            onShowMinimized: comment.isMinimized
                ? () =>
                      setState(() => _shownMinimizedCommentIds.add(comment.id))
                : null,
            onEdit: widget.onEdit,
            onHide: widget.onHide,
            onUnhide: widget.onUnhide,
            onDelete: widget.onDelete,
            onTaskToggle: widget.onTaskToggle,
            taskToggleBusy: widget.taskToggleBusyIds.contains(comment.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final IssueComment comment;
  final bool expandedMinimized;
  final VoidCallback? onShowMinimized;
  final void Function(IssueComment)? onEdit;
  final void Function(IssueComment)? onHide;
  final void Function(IssueComment)? onUnhide;
  final void Function(IssueComment)? onDelete;
  final Future<void> Function(IssueComment, int, bool)? onTaskToggle;
  final bool taskToggleBusy;
  const _CommentCard({
    required this.comment,
    required this.expandedMinimized,
    this.onShowMinimized,
    this.onEdit,
    this.onHide,
    this.onUnhide,
    this.onDelete,
    this.onTaskToggle,
    required this.taskToggleBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (comment.isMinimized && !expandedMinimized) {
      return _MinimizedCommentRow(comment: comment, onShow: onShowMinimized!);
    }
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onVariant = resolveColor(context, ColorTokens.surface.onVariant);
    final canEdit = comment.viewerCanUpdate && onEdit != null;
    // GitHub can report both capabilities while a comment is minimized. Once
    // it is temporarily expanded, it is still minimized remotely, so only
    // the restoration action belongs in the overflow menu.
    final canHide =
        !comment.isMinimized && comment.viewerCanMinimize && onHide != null;
    final canUnhide = comment.viewerCanUnminimize && onUnhide != null;
    final canDelete = comment.viewerCanDelete && onDelete != null;
    final hasActions = canEdit || canHide || canUnhide || canDelete;
    return EditorialCard(
      key: ValueKey('issue-comment-${comment.id}'),
      variation: CardVariation.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StyledText(
                  comment.authorLogin ?? 'ghost',
                  style: editorialTextStyle(
                    TextTokens.label.$large,
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasActions)
                _CommentActionsButton(
                  comment: comment,
                  onEdit: canEdit ? () => onEdit!(comment) : null,
                  onHide: canHide ? () => onHide!(comment) : null,
                  onUnhide: canUnhide ? () => onUnhide!(comment) : null,
                  onDelete: canDelete ? () => onDelete!(comment) : null,
                ),
              if (hasActions) const SizedBox(width: 6),
              StyledText(
                formatRelative(comment.createdAt),
                style: editorialTextStyle(
                  TextTokens.label.$small,
                  color: withOpacity(onVariant, 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GithubHtmlBody(
            html: comment.bodyHtml,
            onTaskToggle: comment.viewerCanUpdate && onTaskToggle != null
                ? (index, checked) => onTaskToggle!(comment, index, checked)
                : null,
            taskToggleBusy: taskToggleBusy,
          ),
        ],
      ),
    );
  }
}

class _MinimizedCommentRow extends StatelessWidget {
  final IssueComment comment;
  final VoidCallback onShow;
  const _MinimizedCommentRow({required this.comment, required this.onShow});

  @override
  Widget build(BuildContext context) {
    final onVariant = resolveColor(context, ColorTokens.surface.onVariant);
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final reason = comment.minimizedReason ?? 'hidden';
    return Container(
      key: ValueKey('issue-comment-minimized-${comment.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: resolveColor(context, ColorTokens.surface.containerHigh),
        borderRadius: BorderRadius.circular(editorialRadiusMedium),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.eyeOff, color: onVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: StyledText(
              'Comment hidden — $reason',
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: onVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: ValueKey('issue-comment-show-${comment.id}'),
            onPressed: onShow,
            child: Text(
              'Show comment',
              style: resolveTextStyle(
                context,
                TextTokens.label.$medium,
              ).copyWith(color: primary, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CommentAction { edit, hide, unhide, delete }

class _CommentActionsButton extends StatelessWidget {
  final IssueComment comment;
  final VoidCallback? onEdit;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  final VoidCallback? onDelete;
  const _CommentActionsButton({
    required this.comment,
    this.onEdit,
    this.onHide,
    this.onUnhide,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    return PopupMenuButton<_CommentAction>(
      key: ValueKey('issue-comment-actions-${comment.id}'),
      tooltip: 'Comment actions',
      icon: const Icon(LucideIcons.ellipsis, size: 18),
      color: surfaceLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: withOpacity(onSurface, 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(editorialRadiusMedium),
      ),
      constraints: const BoxConstraints(minWidth: 208, maxWidth: 280),
      onSelected: (action) => switch (action) {
        _CommentAction.edit => onEdit?.call(),
        _CommentAction.hide => onHide?.call(),
        _CommentAction.unhide => onUnhide?.call(),
        _CommentAction.delete => onDelete?.call(),
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: _CommentAction.edit,
            child: Text('Edit comment'),
          ),
        if (onHide != null)
          const PopupMenuItem(
            value: _CommentAction.hide,
            child: Text('Hide comment'),
          ),
        if (onUnhide != null)
          const PopupMenuItem(
            value: _CommentAction.unhide,
            child: Text('Unhide comment'),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: _CommentAction.delete,
            child: Text('Delete comment'),
          ),
      ],
    );
  }
}
