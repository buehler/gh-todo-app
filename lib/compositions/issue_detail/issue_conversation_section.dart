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

/// "Conversation" section — section header with a count pill and the comment
/// thread rendered oldest-first (no avatars).
///
/// [onEditComment] is invoked when the viewer taps the edit button on one of
/// their own comments (identified by matching login against [viewerLogin]).
class IssueConversationSection extends ConsumerWidget {
  static const pageKey = ValueKey('issue-conversation-section');
  static const commentListKey = ValueKey('issue-conversation-list');

  final String issueId;
  final int commentCount;
  final String? viewerLogin;
  final void Function(IssueComment comment)? onEditComment;
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
    this.viewerLogin,
    this.onEditComment,
    this.onTaskToggle,
    this.taskToggleBusyCommentIds = const {},
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceContainerHigh = resolveColor(
      context,
      ColorTokens.surface.containerHigh,
    );
    final commentsAsync = ref.watch(issueCommentsProvider(issueId));
    final isOffline = ref.watch(offlineStatusProvider).asData?.value ?? false;
    // Prefer the live comment count from the details provider so it reflects
    // freshly-posted / deleted comments after the provider invalidates.
    // Falls back to the feed-provided [commentCount] while details are still
    // loading or have errored.
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
                    .color(surfaceContainerHigh)
                    .borderRounded(999)
                    .paddingOnly(horizontal: 10, vertical: 4),
                child: StyledText(
                  '$liveCount',
                  style: editorialTextStyle(
                    TextTokens.label.$medium,
                    color: onSurfaceVariant,
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
              color: onSurfaceVariant,
            ),
          ),
          data: (comments) => _CommentList(
            comments: comments,
            viewerLogin: viewerLogin,
            onEditComment: onEditComment,
            onTaskToggle: onTaskToggle,
            taskToggleBusyCommentIds: taskToggleBusyCommentIds,
          ),
        ),
      ],
    );
  }
}

class _CommentList extends StatelessWidget {
  final List<IssueComment> comments;
  final String? viewerLogin;
  final void Function(IssueComment comment)? onEditComment;
  final Future<void> Function(
    IssueComment comment,
    int taskIndex,
    bool checked,
  )?
  onTaskToggle;
  final Set<String> taskToggleBusyCommentIds;

  const _CommentList({
    required this.comments,
    required this.viewerLogin,
    required this.onEditComment,
    required this.onTaskToggle,
    required this.taskToggleBusyCommentIds,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    if (comments.isEmpty) {
      return StyledText(
        'No comments yet.',
        style: editorialTextStyle(
          TextTokens.body.$medium,
          color: withOpacity(onSurfaceVariant, 0.7),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      key: IssueConversationSection.commentListKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in comments) ...[
          _CommentCard(
            comment: c,
            editable:
                viewerLogin != null &&
                c.authorLogin != null &&
                viewerLogin == c.authorLogin,
            onEdit: onEditComment,
            onTaskToggle: onTaskToggle,
            taskToggleBusy: taskToggleBusyCommentIds.contains(c.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final IssueComment comment;
  final bool editable;
  final void Function(IssueComment comment)? onEdit;
  final Future<void> Function(
    IssueComment comment,
    int taskIndex,
    bool checked,
  )?
  onTaskToggle;
  final bool taskToggleBusy;

  const _CommentCard({
    required this.comment,
    required this.editable,
    required this.onEdit,
    required this.onTaskToggle,
    required this.taskToggleBusy,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final handler = onEdit;
    final canEdit = editable && handler != null;
    final taskToggle = onTaskToggle;
    final canToggleTasks = editable && taskToggle != null;

    return EditorialCard(
      key: ValueKey('issue-comment-${comment.id}'),
      variation: CardVariation.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const SizedBox(width: 12),
              if (canEdit)
                EditorialIconButton(
                  key: const ValueKey('issue-comment-edit-icon'),
                  icon: LucideIcons.pencil,
                  onPressed: () => handler(comment),
                  tooltip: 'Edit comment',
                  size: 32,
                  variation: IconButtonVariation.ghost,
                ),
              if (canEdit) const SizedBox(width: 6),
              StyledText(
                formatRelative(comment.createdAt),
                style: editorialTextStyle(
                  TextTokens.label.$small,
                  color: withOpacity(onSurfaceVariant, 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GithubHtmlBody(
            html: comment.bodyHtml,
            onTaskToggle: canToggleTasks
                ? (taskIndex, checked) =>
                      taskToggle(comment, taskIndex, checked)
                : null,
            taskToggleBusy: taskToggleBusy,
          ),
        ],
      ),
    );
  }
}
