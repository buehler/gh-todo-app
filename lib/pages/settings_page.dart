import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/add_project_sheet.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet.dart';
import 'package:gh_todos/compositions/settings/pat_management_sheet.dart';
import 'package:gh_todos/compositions/settings/settings_account_section.dart';
import 'package:gh_todos/compositions/settings/settings_projects_section.dart';
import 'package:gh_todos/compositions/settings/settings_section_header.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Settings page showing account info and project list.
class SettingsPage extends StatefulWidget {
  static const pageKey = ValueKey('settings-page');

  final ProjectStorageService projectStorage;
  final AppSessionController sessionController;

  const SettingsPage({
    required this.projectStorage,
    required this.sessionController,
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<Project> _projects;

  @override
  void initState() {
    super.initState();
    _projects = widget.projectStorage.readAll();
  }

  void _refreshProjects() {
    setState(() => _projects = widget.projectStorage.readAll());
  }

  Future<void> _openAddProjectSheet() async {
    final excludeIds = _projects.map((p) => p.id).toSet();
    final project = await showAddProjectSheet(
      context,
      excludeProjectIds: excludeIds,
    );
    if (project == null || !mounted) return;

    await widget.projectStorage.add(project);
    _refreshProjects();
  }

  Future<void> _onProjectTapped(Project project) async {
    final action = await showEditProjectSheet(context, project);
    if (action == null || !mounted) return;

    if (action == EditProjectAction.remove) {
      await widget.projectStorage.remove(project.id);
      _refreshProjects();
    }
  }

  Future<void> _onPatPressed() async {
    final action = await showPatManagementSheet(context);
    if (action == null || !mounted) return;

    switch (action) {
      case PatAction.remove:
        await widget.sessionController.clearToken();
        // Router redirect will navigate to setup automatically.
        break;
      case PatAction.update:
        if (!mounted) return;
        final newToken = await showPatUpdateSheet(context);
        if (newToken == null || !mounted) return;
        await widget.sessionController.setToken(newToken);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            SettingsAccountSection(onPatPressed: _onPatPressed),
            const SizedBox(height: 16),
            const SettingsSectionHeader(label: 'Projects'),
            SettingsProjectsSection(
              projects: _projects,
              onAddPressed: _openAddProjectSheet,
              onProjectTapped: _onProjectTapped,
            ),
          ],
        ),
      ),
    );
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
