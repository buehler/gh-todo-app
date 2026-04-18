import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/settings_operational_help_card.dart';
import 'package:gh_todos/compositions/settings/add_project_sheet.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet.dart';
import 'package:gh_todos/compositions/settings/pat_management_sheet.dart';
import 'package:gh_todos/compositions/settings/settings_account_section.dart';
import 'package:gh_todos/compositions/settings/settings_projects_section.dart';
import 'package:gh_todos/compositions/settings/settings_section_header.dart';
import 'package:gh_todos/compositions/shared/legal_links_row.dart';
import 'package:gh_todos/compositions/shared/pat_scope_help_card.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/auth_metadata_provider.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:mix/mix.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings page showing account info and project list.
class SettingsPage extends ConsumerWidget {
  static const pageKey = ValueKey('settings-page');
  static const tosUrl = 'https://gh-todos.cbue.ch/tos';
  static const privacyUrl = 'https://gh-todos.cbue.ch/privacy';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final metadataAsync = ref.watch(authMetadataProvider);

    final topPadding =
        AppTopBar.effectiveHeight(context) + MediaQuery.paddingOf(context).top;
    // On wide, the bottom nav is replaced by the side rail — skip its height.
    final bottomPadding =
        (isWide(context) ? 0 : AppBottomNav.barHeight) +
        MediaQuery.paddingOf(context).bottom +
        24;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        key: SettingsPage.pageKey,
        padding: EdgeInsets.only(
          top: topPadding + 24,
          bottom: bottomPadding,
          left: 24,
          right: 24,
        ),
        child: ColumnBox(
          style: editorialColumnStyle(
            spacing: 16,
            crossAxis: CrossAxisAlignment.start,
          ).constraints(BoxConstraintsMix.maxWidth(672)),
          children: [
            const _SettingsHeadline(),
            const SizedBox(height: 12),
            const SettingsSectionHeader(label: 'Account'),
            SettingsAccountSection(
              onPatPressed: () => _onPatPressed(context, ref),
              onViewLogsPressed: () => _onViewLogsPressed(context, ref),
              metadata: metadataAsync.asData?.value,
              isLoading: metadataAsync.isLoading,
              errorText: metadataAsync.hasError
                  ? 'Cached token metadata could not be loaded.'
                  : null,
            ),
            const SizedBox(height: 16),
            const SettingsSectionHeader(label: 'PAT Guidance'),
            const PatScopeHelpCard(),
            const SizedBox(height: 16),
            const SettingsSectionHeader(label: 'Project Guidance'),
            const SettingsOperationalHelpCard(),
            const SizedBox(height: 16),
            const SettingsSectionHeader(label: 'Projects'),
            SettingsProjectsSection(
              projects: projects,
              onAddPressed: () => _openAddProjectSheet(context, ref),
              onProjectTapped: (project) =>
                  _onProjectTapped(context, ref, project),
            ),
            const SizedBox(height: 8),
            LegalLinksRow(
              onPrivacyPressed: _urlOpener(SettingsPage.privacyUrl),
              onTermsPressed: _urlOpener(SettingsPage.tosUrl),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddProjectSheet(BuildContext context, WidgetRef ref) async {
    final projects = ref.read(projectListProvider);
    final excludeIds = projects.map((p) => p.id).toSet();
    final project = await showAddProjectSheet(
      context,
      excludeProjectIds: excludeIds,
    );
    if (project == null) return;

    await ref.read(projectListProvider.notifier).add(project);
  }

  Future<void> _onProjectTapped(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final result = await showEditProjectSheet(context, project);
    if (result == null) return;

    switch (result) {
      case RemoveProjectResult():
        await ref.read(projectListProvider.notifier).remove(project.id);
      case UpdateProjectResult(:final project):
        await ref.read(projectListProvider.notifier).update(project);
    }
  }

  Future<void> _onPatPressed(BuildContext context, WidgetRef ref) async {
    final action = await showPatManagementSheet(context);
    if (action == null) return;

    switch (action) {
      case PatAction.remove:
        await ref
            .read(appLoggerProvider)
            .warn('User requested PAT removal.', category: 'settings');
        await ref.read(sessionProvider.notifier).clearToken();
        break;
      case PatAction.update:
        if (!context.mounted) return;
        final newToken = await showPatUpdateSheet(context);
        if (newToken == null) return;
        try {
          await ref
              .read(appLoggerProvider)
              .info('User requested PAT update.', category: 'settings');
          await ref.read(sessionProvider.notifier).updateToken(newToken);
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_patErrorText(error))));
        }
        break;
    }
  }

  Future<void> _onViewLogsPressed(BuildContext context, WidgetRef ref) async {
    await ref
        .read(appLoggerProvider)
        .info('Navigating to application logs.', category: 'settings');
    if (!context.mounted) return;
    await context.pushNamed<void>(AppRoutes.settingsLogsName);
  }

  VoidCallback _urlOpener(String url) {
    final uri = Uri.parse(url);
    return () => launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _patErrorText(Object error) {
    if (error is MissingGithubScopesException) {
      return error.userMessage;
    }
    if (error is InvalidGithubTokenException) {
      return error.message;
    }
    return 'The token could not be updated.';
  }
}

class _SettingsHeadline extends StatelessWidget {
  const _SettingsHeadline();

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return ColumnBox(
      style: editorialColumnStyle(spacing: 6),
      children: [
        StyledText(
          'Settings',
          style: editorialTextStyle(
            TextTokens.headline.$medium,
            color: onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        StyledText(
          'Manage your GitHub connection and editorial workflow.',
          style: editorialTextStyle(
            TextTokens.body.$large,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
