import 'package:gh_todos/graphql/project_fields.graphql.dart';
import 'package:gh_todos/graphql/schema.graphql.dart';
import 'package:gh_todos/providers/graphql_provider.dart';
import 'package:graphql/client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_fields_provider.g.dart';

/// A single option of a GitHub Projects V2 single-select field.
class ProjectFieldOption {
  final String id;
  final String name;

  /// GitHub's own color name for the option (e.g. "RED", "ORANGE"). Kept as
  /// a raw string — the app maps options to its own palette via the user's
  /// mapping, so this is only useful as an incidental hint.
  final String? color;

  const ProjectFieldOption({
    required this.id,
    required this.name,
    this.color,
  });
}

/// Kinds of project fields we care about for local mappings. Other field
/// kinds returned by GitHub (text, number, iteration, assignees, etc.) are
/// intentionally filtered out.
enum ProjectFieldKind { date, singleSelect }

/// Lightweight DTO exposed to the UI so widgets don't depend on the verbose
/// `graphql_codegen`-generated types directly.
class ProjectFieldInfo {
  final String id;
  final String name;
  final ProjectFieldKind kind;
  final List<ProjectFieldOption> options;

  const ProjectFieldInfo({
    required this.id,
    required this.name,
    required this.kind,
    this.options = const [],
  });
}

/// Fetches the date + single-select fields of a GitHub Projects V2 project.
///
/// The query requests the first 100 fields. Projects with more than 100 custom
/// fields exist in theory but are rare; re-add pagination variables to the
/// query if that bites someone.
@riverpod
Stream<List<ProjectFieldInfo>> projectFields(
  Ref ref,
  String projectId,
) {
  final client = ref.watch(graphqlClientProvider);
  final observable = client.watchQuery$ProjectFields(
    WatchOptions$Query$ProjectFields(
      variables: Variables$Query$ProjectFields(projectId: projectId),
      fetchPolicy: FetchPolicy.cacheAndNetwork,
      eagerlyFetchResults: true,
      fetchResults: true,
    ),
  );
  ref.onDispose(observable.close);

  return observable.stream.map((result) {
    if (result.parsedData == null) {
      if (!result.isLoading && result.hasException) {
        throw result.exception!;
      }
      return const <ProjectFieldInfo>[];
    }

    final node = result.parsedData?.node;
    if (node is! Query$ProjectFields$node$$ProjectV2) return [];

    final fields = <ProjectFieldInfo>[];
    for (final raw in node.fields.nodes ?? const []) {
      if (raw == null) continue;

      if (raw
              is Query$ProjectFields$node$$ProjectV2$fields$nodes$$ProjectV2Field &&
          raw.dataType == Enum$ProjectV2FieldType.DATE) {
        fields.add(
          ProjectFieldInfo(
            id: raw.id,
            name: raw.name,
            kind: ProjectFieldKind.date,
          ),
        );
      } else if (raw
              is Query$ProjectFields$node$$ProjectV2$fields$nodes$$ProjectV2SingleSelectField &&
          raw.dataType == Enum$ProjectV2FieldType.SINGLE_SELECT) {
        fields.add(
          ProjectFieldInfo(
            id: raw.id,
            name: raw.name,
            kind: ProjectFieldKind.singleSelect,
            options: raw.options
                .map(
                  (o) => ProjectFieldOption(
                    id: o.id,
                    name: o.name,
                    color: o.color.name,
                  ),
                )
                .toList(growable: false),
          ),
        );
      }
    }

    return fields;
  });
}
