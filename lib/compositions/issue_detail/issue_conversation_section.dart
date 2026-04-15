import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/issue_detail/add_comment_composer.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// "Conversation" section — section header with a count pill, the comment
/// thread rendered oldest-first (no avatars), and an always-visible composer
/// anchored at the bottom of the transcript.
///
/// [onPostComment] is invoked with the draft body when the user taps the
/// composer's submit button. Returns `true` on success so the composer can
/// clear. [onEditComment] is invoked when the viewer taps one of their own
/// comments (identified by matching login against [viewerLogin]).
class IssueConversationSection extends ConsumerWidget {
  static const pageKey = ValueKey('issue-conversation-section');
  static const commentListKey = ValueKey('issue-conversation-list');

  final String issueId;
  final int commentCount;
  final String? viewerLogin;
  final Future<bool> Function(String body)? onPostComment;
  final void Function(IssueComment comment)? onEditComment;

  const IssueConversationSection({
    required this.issueId,
    required this.commentCount,
    this.viewerLogin,
    this.onPostComment,
    this.onEditComment,
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
    final detailsAsync = ref.watch(issueDetailsProvider(issueId));
    // Prefer the live comment count from the details provider so it reflects
    // freshly-posted / deleted comments after the provider invalidates.
    // Falls back to the feed-provided [commentCount] while details are still
    // loading or have errored.
    final liveCount = detailsAsync.asData?.value.comments.length ?? commentCount;

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
        detailsAsync.when(
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
            'Failed to load conversation.',
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: onSurfaceVariant,
            ),
          ),
          data: (details) => _CommentList(
            comments: details.comments,
            viewerLogin: viewerLogin,
            onEditComment: onEditComment,
          ),
        ),
        const SizedBox(height: 8),
        AddCommentComposer(onSubmit: onPostComment),
      ],
    );
  }
}

class _CommentList extends StatelessWidget {
  final List<IssueComment> comments;
  final String? viewerLogin;
  final void Function(IssueComment comment)? onEditComment;

  const _CommentList({
    required this.comments,
    required this.viewerLogin,
    required this.onEditComment,
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

  const _CommentCard({
    required this.comment,
    required this.editable,
    required this.onEdit,
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

    return EditorialCard(
      key: ValueKey('issue-comment-${comment.id}'),
      variation: CardVariation.elevated,
      padding: const EdgeInsets.all(16),
      onTap: canEdit ? () => handler(comment) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
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
                Padding(
                  key: const ValueKey('issue-comment-edit-icon'),
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 14,
                    color: withOpacity(onSurfaceVariant, 0.6),
                  ),
                ),
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
          SelectableText(
            comment.body,
            style: resolveTextStyle(
              context,
              TextTokens.body.$medium,
            ).copyWith(color: onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}
