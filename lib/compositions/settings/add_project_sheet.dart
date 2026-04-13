import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/user_orgs.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mix/mix.dart';

/// Shows a modal bottom sheet that lets the user pick an owner (self or org)
/// and then select a GitHub project to add.
///
/// Projects whose IDs are in [excludeProjectIds] are filtered out.
/// Returns the selected [Project] or `null` if dismissed.
Future<Project?> showAddProjectSheet(
  BuildContext context, {
  Set<String> excludeProjectIds = const {},
}) {
  final client = GraphQLProvider.of(context).value;

  return showModalBottomSheet<Project>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GraphQLProvider(
      client: ValueNotifier(client),
      child: _AddProjectSheet(excludeProjectIds: excludeProjectIds),
    ),
  );
}

class _Owner {
  final String id;
  final String login;

  const _Owner({required this.id, required this.login});
}

class _AddProjectSheet extends StatefulWidget {
  final Set<String> excludeProjectIds;

  const _AddProjectSheet({required this.excludeProjectIds});

  @override
  State<_AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<_AddProjectSheet> {
  _Owner? _explicitOwner;

  void _selectOwner(_Owner owner) => setState(() => _explicitOwner = owner);

  @override
  Widget build(BuildContext context) {
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Query$UserInformation$Widget(
            builder: (userResult, {fetchMore, refetch}) {
              final viewer = userResult.parsedData?.viewer;
              if (viewer == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final viewerOwner = _Owner(
                id: viewer.id,
                login: viewer.login,
              );
              final activeOwner = _explicitOwner ?? viewerOwner;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DragHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: _SheetHeader(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _OwnerDropdownLoader(
                      viewerOwner: viewerOwner,
                      selectedId: activeOwner.id,
                      onChanged: _selectOwner,
                    ),
                  ),
                  const SizedBox(height: 16),
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
          ),
        );
      },
    );
  }
}

class _OwnerDropdownLoader extends StatelessWidget {
  final _Owner viewerOwner;
  final String selectedId;
  final ValueChanged<_Owner> onChanged;

  const _OwnerDropdownLoader({
    required this.viewerOwner,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Query$UserOrganizations$Widget(
      builder: (orgsResult, {fetchMore, refetch}) {
        final orgs = orgsResult.parsedData?.viewer.organizations.nodes
                ?.whereType<
                    Query$UserOrganizations$viewer$organizations$nodes>()
                .toList() ??
            [];

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

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: withOpacity(outlineVariant, 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    return StyledText(
      'Add Project',
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
    final surfaceLow = resolveColor(
      context,
      ColorTokens.surface.containerLow,
    );
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

class _ProjectList extends StatelessWidget {
  final String ownerId;
  final String ownerLogin;
  final Set<String> excludeProjectIds;
  final ScrollController scrollController;

  const _ProjectList({
    required this.ownerId,
    required this.ownerLogin,
    required this.excludeProjectIds,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Query$OwnerProjects$Widget(
      options: Options$Query$OwnerProjects(
        variables: Variables$Query$OwnerProjects(ownerId: ownerId),
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading && result.parsedData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = _extractProjects(result.parsedData?.node)
            .where((p) => !excludeProjectIds.contains(p.id))
            .toList();

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
                Project(
                  id: p.id,
                  name: p.title,
                  ownerLogin: ownerLogin,
                ),
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

List<_ProjectData> _extractProjects(Query$OwnerProjects$node? node) {
  if (node == null) return [];

  if (node is Query$OwnerProjects$node$$Organization) {
    return node.projectsV2.nodes
            ?.whereType<
                Query$OwnerProjects$node$$Organization$projectsV2$nodes>()
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
