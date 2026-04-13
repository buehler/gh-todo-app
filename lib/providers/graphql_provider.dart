import 'package:gh_todos/providers/session_provider.dart';
import 'package:graphql/client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'graphql_provider.g.dart';

@Riverpod(keepAlive: true)
GraphQLClient graphqlClient(Ref ref) {
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
    cache: GraphQLCache(),
  );
}
