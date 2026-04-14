import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/add_project_sheet.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet.dart';
import 'package:gh_todos/compositions/settings/pat_management_sheet.dart';
import 'package:gh_todos/compositions/settings/settings_account_section.dart';
import 'package:gh_todos/compositions/settings/settings_projects_section.dart';
import 'package:gh_todos/compositions/settings/settings_section_header.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Settings page showing account info and project list.
class SettingsPage extends ConsumerWidget {
  static const pageKey = ValueKey('settings-page');

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    final topPadding = AppTopBar.barHeight + MediaQuery.paddingOf(context).top;
    final bottomPadding =
        AppBottomNav.barHeight + MediaQuery.paddingOf(context).bottom + 24;

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
            ),
            const SizedBox(height: 16),
            const SettingsSectionHeader(label: 'Projects'),
            SettingsProjectsSection(
              projects: projects,
              onAddPressed: () => _openAddProjectSheet(context, ref),
              onProjectTapped: (project) =>
                  _onProjectTapped(context, ref, project),
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
    project,
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
        await ref.read(projectStorageProvider).save([]);
        await ref.read(sessionProvider.notifier).clearToken();
        break;
      case PatAction.update:
        if (!context.mounted) return;
        final newToken = await showPatUpdateSheet(context);
        if (newToken == null) return;
        await ref.read(sessionProvider.notifier).setToken(newToken);
        break;
    }
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
