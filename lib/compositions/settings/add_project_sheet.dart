import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/adaptive_sheet.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/user_projects.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Shows a modal bottom sheet that lets the user pick a project owned by the
/// viewer, an organization, or an explicitly entered GitHub user.
///
/// Projects whose IDs are in [excludeProjectIds] are filtered out.
/// Returns the selected [Project] or `null` if dismissed.
Future<Project?> showAddProjectSheet(
  BuildContext context, {
  Set<String> excludeProjectIds = const {},
}) {
  return showAdaptiveSheet<Project>(
    context,
    dialogMaxWidth: 560,
    builder: (_, isDialog) => _AddProjectSheet(
      excludeProjectIds: excludeProjectIds,
      isDialog: isDialog,
    ),
  );
}

class _Owner {
  final String id;
  final String login;

  const _Owner({required this.id, required this.login});
}

enum _AddProjectMode { owned, otherUser }

class _AddProjectSheet extends ConsumerStatefulWidget {
  final Set<String> excludeProjectIds;
  final bool isDialog;

  const _AddProjectSheet({
    required this.excludeProjectIds,
    required this.isDialog,
  });

  @override
  ConsumerState<_AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends ConsumerState<_AddProjectSheet> {
  final _usernameController = TextEditingController();
  _AddProjectMode _mode = _AddProjectMode.owned;
  _Owner? _explicitOwner;
  String? _submittedLogin;

  void _selectOwner(_Owner owner) => setState(() => _explicitOwner = owner);

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userInfoProvider);

    if (widget.isDialog) return _buildDialogBody(context, userAsync);
    return _buildSheetBody(context, userAsync);
  }

  Widget _buildInner(
    BuildContext context,
    AsyncValue<Query$UserInformation$viewer?> userAsync,
    ScrollController? scrollController,
  ) {
    if (_mode == _AddProjectMode.otherUser) {
      return _buildOtherUserView(context, scrollController);
    }

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load user')),
      data: (viewer) {
        if (viewer == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final viewerOwner = _Owner(id: viewer.id, login: viewer.login);
        final activeOwner = _explicitOwner ?? viewerOwner;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveSheetDragHandle(isDialog: widget.isDialog),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                widget.isDialog ? 24 : 0,
                24,
                16,
              ),
              child: const _SheetHeader(title: 'Add Project'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _OwnerDropdownLoader(
                viewerOwner: viewerOwner,
                selectedId: activeOwner.id,
                onChanged: _selectOwner,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: EditorialButton(
                  label: 'From another user',
                  leadingIcon: LucideIcons.userSearch,
                  variation: ButtonVariation.secondary,
                  onPressed: _showOtherUserView,
                ),
              ),
            ),
            _Divider(),
            Expanded(
              child: _ProjectList(
                ownerId: activeOwner.id,
                ownerLogin: activeOwner.login,
                excludeProjectIds: widget.excludeProjectIds,
                scrollController: scrollController,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtherUserView(
    BuildContext context,
    ScrollController? scrollController,
  ) {
    final submittedLogin = _submittedLogin;
    final projectsAsync = submittedLogin == null
        ? null
        : ref.watch(userProjectsProvider(submittedLogin));
    final isLoading = projectsAsync?.isLoading ?? false;
    final canSubmit =
        _normalizeLogin(_usernameController.text).isNotEmpty && !isLoading;
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSheetDragHandle(isDialog: widget.isDialog),
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.isDialog ? 16 : 0, 24, 12),
          child: Row(
            children: [
              EditorialIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Back',
                variation: IconButtonVariation.ghost,
                onPressed: _showOwnedView,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _SheetHeader(title: 'Add from another user'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledText(
                'Enter the exact GitHub username of the personal project owner.',
                style: editorialTextStyle(
                  TextTokens.body.$small,
                  color: onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              EditorialTextField(
                controller: _usernameController,
                label: 'GitHub username',
                hintText: 'octocat',
                prefixIcon: LucideIcons.atSign,
                enabled: !isLoading,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _handleUsernameChanged,
                onSubmitted: (_) => _submitUsername(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: EditorialButton(
                  label: 'Find projects',
                  leadingIcon: LucideIcons.search,
                  loading: isLoading,
                  enabled: canSubmit,
                  onPressed: canSubmit ? _submitUsername : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Divider(),
        Expanded(
          child: _OtherUserProjectResults(
            projectsAsync: projectsAsync,
            submittedLogin: submittedLogin,
            excludeProjectIds: widget.excludeProjectIds,
            scrollController: scrollController,
            onRetry: submittedLogin == null ? null : _submitUsername,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogBody(
    BuildContext context,
    AsyncValue<Query$UserInformation$viewer?> userAsync,
  ) {
    // Dialog has a bounded height courtesy of the adapter's maxHeight cap; the
    // inner list uses its default scroll physics (no shared scrollController).
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: _buildInner(context, userAsync, null),
    );
  }

  Widget _buildSheetBody(
    BuildContext context,
    AsyncValue<Query$UserInformation$viewer?> userAsync,
  ) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _buildInner(context, userAsync, scrollController),
        );
      },
    );
  }

  void _showOtherUserView() {
    setState(() {
      _mode = _AddProjectMode.otherUser;
      _submittedLogin = null;
    });
  }

  void _showOwnedView() {
    setState(() {
      _mode = _AddProjectMode.owned;
      _submittedLogin = null;
    });
  }

  void _handleUsernameChanged(String value) {
    if (_normalizeLogin(value) == _submittedLogin) return;
    setState(() => _submittedLogin = null);
  }

  void _submitUsername() {
    final login = _normalizeLogin(_usernameController.text);
    if (login.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.invalidate(userProjectsProvider(login));
    setState(() => _submittedLogin = login);
  }
}

String _normalizeLogin(String input) {
  final trimmed = input.trim();
  return trimmed.startsWith('@') ? trimmed.substring(1).trim() : trimmed;
}

class _OwnerDropdownLoader extends ConsumerWidget {
  final _Owner viewerOwner;
  final String selectedId;
  final ValueChanged<_Owner> onChanged;

  const _OwnerDropdownLoader({
    required this.viewerOwner,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(userOrganizationsProvider);

    return orgsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _OwnerDropdown(
        owners: [viewerOwner],
        selectedId: selectedId,
        onChanged: onChanged,
      ),
      data: (orgs) {
        final owners = <_Owner>[
          viewerOwner,
          for (final org in orgs) _Owner(id: org.id, login: org.login),
        ];

        return _OwnerDropdown(
          owners: owners,
          selectedId: selectedId,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;

  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    return StyledText(
      title,
      style: editorialTextStyle(
        TextTokens.headline.$medium,
        color: onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    return Box(
      style: BoxStyler()
          .height(1)
          .color(withOpacity(outlineVariant, 0.15))
          .width(double.infinity),
    );
  }
}

class _OwnerDropdown extends StatelessWidget {
  final List<_Owner> owners;
  final String selectedId;
  final ValueChanged<_Owner> onChanged;

  const _OwnerDropdown({
    required this.owners,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    final dropdownStyle = resolveTextStyle(
      context,
      TextTokens.body.$medium,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        border: Border.all(color: withOpacity(outlineVariant, 0.15)),
      ),
      child: DropdownButton<String>(
        value: selectedId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: dropdownStyle,
        dropdownColor: surfaceLow,
        borderRadius: BorderRadius.circular(editorialRadiusSmall),
        items: [
          for (final owner in owners)
            DropdownMenuItem(
              value: owner.id,
              child: Text(owner.login, style: dropdownStyle),
            ),
        ],
        onChanged: (id) {
          if (id == null) return;
          final owner = owners.firstWhere((o) => o.id == id);
          onChanged(owner);
        },
      ),
    );
  }
}

class _OtherUserProjectResults extends StatelessWidget {
  final AsyncValue<Query$UserProjects$user?>? projectsAsync;
  final String? submittedLogin;
  final Set<String> excludeProjectIds;
  final ScrollController? scrollController;
  final VoidCallback? onRetry;

  const _OtherUserProjectResults({
    required this.projectsAsync,
    required this.submittedLogin,
    required this.excludeProjectIds,
    required this.scrollController,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final asyncValue = projectsAsync;
    if (asyncValue == null) {
      return const _LookupState(
        title: 'Enter a username',
        message: 'Projects are loaded only after you submit an exact login.',
      );
    }

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _LookupState(
        title: 'Could not load projects',
        message: 'Check the username and token access, then try again.',
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
      data: (user) {
        if (user == null) {
          return _LookupState(
            title: 'User not found',
            message: 'No GitHub user exists with the login @$submittedLogin.',
          );
        }

        final projects = _extractUserProjects(
          user,
        ).where((project) => !excludeProjectIds.contains(project.id)).toList();
        if (projects.isEmpty) {
          return _LookupState(
            title: 'No open projects found',
            message:
                'No readable, open personal projects were found for @${user.login}.',
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _ProjectRow(
              title: project.title,
              description: project.shortDescription,
              onTap: () => Navigator.pop(
                context,
                Project(
                  id: project.id,
                  name: project.title,
                  ownerLogin: user.login,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LookupState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _LookupState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledText(
              title,
              style: editorialTextStyle(
                TextTokens.title.$medium,
                color: onSurface,
                fontWeight: FontWeight.w700,
              ).textAlign(TextAlign.center),
            ),
            const SizedBox(height: 6),
            StyledText(
              message,
              style: editorialTextStyle(
                TextTokens.body.$small,
                color: onSurfaceVariant,
              ).textAlign(TextAlign.center),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              EditorialButton(
                label: actionLabel!,
                variation: ButtonVariation.tertiary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectList extends ConsumerWidget {
  final String ownerId;
  final String ownerLogin;
  final Set<String> excludeProjectIds;
  final ScrollController? scrollController;

  const _ProjectList({
    required this.ownerId,
    required this.ownerLogin,
    required this.excludeProjectIds,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(ownerProjectsProvider(ownerId));

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load projects')),
      data: (node) {
        final projects = _extractProjects(
          node,
        ).where((p) => !excludeProjectIds.contains(p.id)).toList();

        if (projects.isEmpty) {
          return _EmptyState();
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final p = projects[index];
            return _ProjectRow(
              title: p.title,
              description: p.shortDescription,
              onTap: () => Navigator.pop(
                context,
                Project(id: p.id, name: p.title, ownerLogin: ownerLogin),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProjectData {
  final String id;
  final String title;
  final String? shortDescription;

  const _ProjectData({
    required this.id,
    required this.title,
    this.shortDescription,
  });
}

List<_ProjectData> _extractUserProjects(Query$UserProjects$user user) {
  return user.projectsV2.nodes
          ?.whereType<Query$UserProjects$user$projectsV2$nodes>()
          .where((project) => !project.closed)
          .map(
            (project) => _ProjectData(
              id: project.id,
              title: project.title,
              shortDescription: project.shortDescription,
            ),
          )
          .toList() ??
      [];
}

List<_ProjectData> _extractProjects(Query$OwnerProjects$node? node) {
  if (node == null) return [];

  if (node is Query$OwnerProjects$node$$Organization) {
    return node.projectsV2.nodes
            ?.whereType<
              Query$OwnerProjects$node$$Organization$projectsV2$nodes
            >()
            .where((p) => !p.closed)
            .map(
              (p) => _ProjectData(
                id: p.id,
                title: p.title,
                shortDescription: p.shortDescription,
              ),
            )
            .toList() ??
        [];
  }

  if (node is Query$OwnerProjects$node$$User) {
    return node.projectsV2.nodes
            ?.whereType<Query$OwnerProjects$node$$User$projectsV2$nodes>()
            .where((p) => !p.closed)
            .map(
              (p) => _ProjectData(
                id: p.id,
                title: p.title,
                shortDescription: p.shortDescription,
              ),
            )
            .toList() ??
        [];
  }

  return [];
}

class _ProjectRow extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback onTap;

  const _ProjectRow({
    required this.title,
    this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );

    return PressableBox(
      onPress: onTap,
      style: BoxStyler()
          .color(Colors.transparent)
          .paddingOnly(horizontal: 24, vertical: 14)
          .animate(editorialAnimation)
          .onHovered(BoxStyler().color(surfaceHighest)),
      child: ColumnBox(
        style: editorialColumnStyle(
          spacing: 4,
          crossAxis: CrossAxisAlignment.start,
        ),
        children: [
          StyledText(
            title,
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description != null && description!.isNotEmpty)
            StyledText(
              description!,
              style: editorialTextStyle(
                TextTokens.body.$small,
                color: onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    return Center(
      child: StyledText(
        'No open projects found.',
        style: editorialTextStyle(
          TextTokens.body.$medium,
          color: onSurfaceVariant,
        ),
      ),
    );
  }
}
