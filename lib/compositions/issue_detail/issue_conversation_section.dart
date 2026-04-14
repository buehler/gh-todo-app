import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:gh_todos/util/dates.dart';
import 'package:mix/mix.dart';

/// "Conversation" section — section header with a count pill, then the
/// comment thread rendered newest-first (no avatars).
class IssueConversationSection extends ConsumerWidget {
  static const pageKey = ValueKey('issue-conversation-section');
  static const commentListKey = ValueKey('issue-conversation-list');

  final String issueId;
  final int commentCount;

  const IssueConversationSection({
    required this.issueId,
    required this.commentCount,
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
            if (commentCount > 0)
              Box(
                style: BoxStyler()
                    .color(surfaceContainerHigh)
                    .borderRounded(999)
                    .paddingOnly(horizontal: 10, vertical: 4),
                child: StyledText(
                  '$commentCount',
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
          data: (details) => _CommentList(comments: details.comments),
        ),
      ],
    );
  }
}

class _CommentList extends StatelessWidget {
  final List<IssueComment> comments;

  const _CommentList({required this.comments});

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
          _CommentCard(comment: c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final IssueComment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

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
