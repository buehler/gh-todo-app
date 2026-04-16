import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// "Description" section — section heading + a card containing the issue's
/// `bodyText` as selectable plain text.
///
/// Watches [issueDetailsProvider] for the `description` field. While loading,
/// shows a minimal spinner. On error, shows a muted error line.
class IssueDescriptionSection extends ConsumerWidget {
  static const pageKey = ValueKey('issue-description-section');

  final String issueId;

  const IssueDescriptionSection({required this.issueId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final detailsAsync = ref.watch(issueDetailsProvider(issueId));
    final isOffline = ref.watch(offlineStatusProvider).asData?.value ?? false;

    return ColumnBox(
      key: pageKey,
      style: editorialColumnStyle(
        spacing: 12,
        crossAxis: CrossAxisAlignment.stretch,
      ),
      children: [
        StyledText(
          'Description',
          style: editorialTextStyle(
            TextTokens.title.$large,
            color: onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        EditorialCard(
          variation: CardVariation.recessed,
          padding: const EdgeInsets.all(20),
          child: detailsAsync.when(
            loading: () => const SizedBox(
              height: 48,
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
                  ? 'Offline. Description is unavailable until this issue has been loaded once.'
                  : 'Failed to load description.',
              style: editorialTextStyle(
                TextTokens.body.$medium,
                color: onSurfaceVariant,
              ),
            ),
            data: (details) {
              final body = details.description;
              if (body == null) {
                return StyledText(
                  'No description provided.',
                  style: editorialTextStyle(
                    TextTokens.body.$medium,
                    color: withOpacity(onSurfaceVariant, 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return SelectableText(
                body,
                style: resolveTextStyle(
                  context,
                  TextTokens.body.$medium,
                ).copyWith(color: onSurfaceVariant, height: 1.5),
              );
            },
          ),
        ),
      ],
    );
  }
}
