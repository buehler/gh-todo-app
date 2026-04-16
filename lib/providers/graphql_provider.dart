import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'graphql_provider.g.dart';

@Riverpod(keepAlive: true)
GraphQLClient graphqlClient(Ref ref) {
  ref.watch(hiveBootstrapProvider).requireValue;
  final session = ref.watch(sessionProvider);

  return GraphQLClient(
    link: AuthLink(
      getToken: () async {
        if (session.value?.hasToken != true) return null;
        final notifier = ref.read(sessionProvider.notifier);
        final token = await notifier.readToken();
        return token != null ? 'Bearer $token' : null;
      },
    ).concat(HttpLink('https://api.github.com/graphql')),
    cache: GraphQLCache(store: HiveStore()),
  );
}
