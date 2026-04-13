import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/graphql/owner_projects.graphql.dart';
import 'package:gh_todos/graphql/user_orgs.graphql.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/providers/graphql_provider.dart';

final userInfoProvider =
    FutureProvider.autoDispose<Query$UserInformation$viewer?>((ref) async {
  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$UserInformation();
  return result.parsedData?.viewer;
});

final userOrganizationsProvider = FutureProvider.autoDispose<
    List<Query$UserOrganizations$viewer$organizations$nodes>>((ref) async {
  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$UserOrganizations();
  return result.parsedData?.viewer.organizations.nodes
          ?.whereType<Query$UserOrganizations$viewer$organizations$nodes>()
          .toList() ??
      [];
});

final ownerProjectsProvider = FutureProvider.autoDispose
    .family<Query$OwnerProjects$node?, String>((ref, ownerId) async {
  final client = ref.watch(graphqlClientProvider);
  final result = await client.query$OwnerProjects(
    Options$Query$OwnerProjects(
      variables: Variables$Query$OwnerProjects(ownerId: ownerId),
    ),
  );
  return result.parsedData?.node;
});
