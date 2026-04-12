import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/settings/add_project_sheet.dart';
import 'package:gh_todos/compositions/settings/settings_account_section.dart';
import 'package:gh_todos/compositions/settings/settings_projects_section.dart';
import 'package:gh_todos/compositions/settings/settings_section_header.dart';
import 'package:gh_todos/compositions/shell/app_bottom_nav.dart';
import 'package:gh_todos/compositions/shell/app_top_bar.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/services/project_storage_service.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Settings page showing account info and project list.
///
/// Hosted inside the app shell — top bar and bottom nav are provided
/// externally via [AppShell].
class SettingsPage extends StatefulWidget {
  static const pageKey = ValueKey('settings-page');

  final ProjectStorageService projectStorage;

  const SettingsPage({required this.projectStorage, super.key});

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

  Future<void> _openAddProjectSheet() async {
    final project = await showAddProjectSheet(context);
    if (project == null || !mounted) return;

    await widget.projectStorage.add(project);
    setState(() => _projects = widget.projectStorage.readAll());
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
            const SettingsAccountSection(),
            const SizedBox(height: 16),
            const SettingsSectionHeader(label: 'Projects'),
            SettingsProjectsSection(
              projects: _projects,
              onAddPressed: _openAddProjectSheet,
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
