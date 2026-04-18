import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/services/app_logger_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'graphql_provider.g.dart';

final githubGraphqlTransportLinkProvider = Provider<Link>((ref) {
  final session = ref.watch(sessionProvider);

  return AuthLink(
    getToken: () async {
      if (session.value?.hasToken != true) return null;
      final notifier = ref.read(sessionProvider.notifier);
      final token = await notifier.readToken();
      return token != null ? 'Bearer $token' : null;
    },
  ).concat(HttpLink('https://api.github.com/graphql'));
});

final graphqlStoreProvider = Provider<Store>((ref) {
  ref.watch(hiveBootstrapProvider);
  return HiveStore();
});

@Riverpod(keepAlive: true)
GraphQLClient graphqlClient(Ref ref) {
  final transportLink = ref.watch(githubGraphqlTransportLinkProvider);
  final store = ref.watch(graphqlStoreProvider);
  final logger = ref.read(appLoggerProvider);

  return GraphQLClient(
    link: _GraphqlLoggingLink(logger: logger).concat(transportLink),
    cache: GraphQLCache(store: store),
  );
}

class _GraphqlLoggingLink extends Link {
  _GraphqlLoggingLink({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final operationName = _operationName(request.operation);
    unawaited(
      _logger.debug(
        '${_operationKind(request.operation)}: $operationName',
        category: 'graphql',
      ),
    );
    return forward?.call(request) ?? const Stream<Response>.empty();
  }

  String _operationName(Operation operation) {
    final explicitName = operation.operationName;
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    for (final definition in operation.document.definitions) {
      final dynamic operationDefinition = definition;
      final dynamic nameNode = operationDefinition.name;
      final name = nameNode?.value;
      if (name is String && name.isNotEmpty) return name;
      break;
    }

    return 'anonymous';
  }

  String _operationKind(Operation operation) {
    for (final definition in operation.document.definitions) {
      final dynamic operationDefinition = definition;
      final type = operationDefinition.type;
      if (type == null) continue;
      return '$type'.split('.').last;
    }
    return 'operation';
  }
}
