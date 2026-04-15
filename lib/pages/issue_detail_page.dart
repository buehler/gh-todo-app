import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/issue_detail/issue_conversation_section.dart';
import 'package:gh_todos/compositions/issue_detail/issue_description_section.dart';
import 'package:gh_todos/compositions/issue_detail/issue_detail_menu.dart';
import 'package:gh_todos/compositions/issue_detail/issue_detail_top_bar.dart';
import 'package:gh_todos/compositions/issue_detail/issue_header_section.dart';
import 'package:gh_todos/compositions/issue_detail/issue_state_action.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:mix/mix.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen, push-routed detail view for a single GitHub issue.
///
/// Lives outside the [StatefulShellRoute], so it owns its own [Scaffold] and
/// replaces the shell's top bar with its own back-button header.
///
/// The header (title, priority, #number, dates) renders immediately from the
/// [issue] that was passed via `GoRouterState.extra` when navigating from the
/// feed. The description + conversation are fetched lazily by the child
/// sections via `issueDetailsProvider`.
class IssueDetailPage extends ConsumerWidget {
  static const pageKey = ValueKey('issue-detail-page');
  static const scrollKey = ValueKey('issue-detail-scroll');

  final String issueId;
  final IssueData issue;

  const IssueDetailPage({
    required this.issueId,
    required this.issue,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding =
        IssueDetailTopBar.barHeight + MediaQuery.paddingOf(context).top;
    // Leave a bit of breathing room below the composer for the safe-area
    // (home-indicator) and the on-screen keyboard's clearance.
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 32;

    return Scaffold(
      key: pageKey,
      backgroundColor: resolveColor(context, ColorTokens.background.$default),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              key: scrollKey,
              padding: EdgeInsets.only(
                top: topPadding + 24,
                left: 24,
                right: 24,
                bottom: bottomPadding,
              ),
              child: ColumnBox(
                style: FlexBoxStyler().flex(
                  FlexStyler()
                      .direction(Axis.vertical)
                      .crossAxisAlignment(CrossAxisAlignment.stretch)
                      .mainAxisSize(MainAxisSize.min)
                      .spacing(32),
                ),
                children: [
                  IssueHeaderSection(issue: issue),
                  IssueStateAction(
                    issue: issue,
                    // TODO(state): wire up close / re-open mutation.
                    onPressed: () {},
                  ),
                  IssueDescriptionSection(issueId: issueId),
                  IssueConversationSection(
                    issueId: issueId,
                    commentCount: issue.commentCount,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IssueDetailTopBar(
              onBack: () => context.pop(),
              onMenuAction: (action) => _handleMenuAction(action, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(IssueDetailMenuAction action, WidgetRef ref) {
    switch (action) {
      case IssueDetailMenuAction.editIssue:
        // TODO(edit): wire up the edit-issue flow.
        break;
      case IssueDetailMenuAction.openInBrowser:
        unawaited(_openInBrowser(ref));
        break;
    }
  }

  /// Launches the issue's canonical GitHub URL in the system browser.
  ///
  /// The URL is fetched lazily via `issueDetailsProvider`; if it hasn't
  /// resolved yet (menu tapped before the detail payload lands), await the
  /// future so the action doesn't silently no-op. Failures are swallowed — the
  /// user can always retry.
  Future<void> _openInBrowser(WidgetRef ref) async {
    final String? url;
    try {
      final details = await ref.read(issueDetailsProvider(issueId).future);
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
