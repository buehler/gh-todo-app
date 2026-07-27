import 'package:graphql/client.dart';

class FakeGithubGraphqlAccount {
  final FakeGithubGraphqlViewer viewer;
  final List<FakeGithubGraphqlOrg> organizations;
  final List<FakeGithubGraphqlUser> otherUsers;
  final Map<String, List<FakeGithubGraphqlProject>> projectsByOwnerId;

  const FakeGithubGraphqlAccount({
    required this.viewer,
    this.organizations = const [],
    this.otherUsers = const [],
    this.projectsByOwnerId = const {},
  });
}

class FakeGithubGraphqlViewer {
  final String id;
  final String login;
  final String? name;
  final String avatarUrl;

  const FakeGithubGraphqlViewer({
    required this.id,
    required this.login,
    required this.name,
    required this.avatarUrl,
  });
}

class FakeGithubGraphqlOrg {
  final String id;
  final String login;

  const FakeGithubGraphqlOrg({required this.id, required this.login});
}

class FakeGithubGraphqlUser {
  final String login;
  final List<FakeGithubGraphqlProject> projects;

  const FakeGithubGraphqlUser({required this.login, this.projects = const []});
}

class FakeGithubGraphqlProject {
  final String id;
  final String title;
  final String? shortDescription;
  final bool closed;

  const FakeGithubGraphqlProject({
    required this.id,
    required this.title,
    this.shortDescription,
    this.closed = false,
  });
}

GraphQLClient createFakeGithubGraphqlClient({
  required Future<String?> Function() readToken,
  required Map<String, FakeGithubGraphqlAccount> accountsByToken,
  void Function(String operationName)? onOperation,
  GraphQLError? Function(String operationName, Map<String, dynamic> variables)?
  operationError,
}) {
  return GraphQLClient(
    link:
        AuthLink(
          getToken: () async {
            final token = await readToken();
            return token == null ? null : 'Bearer $token';
          },
        ).concat(
          _FakeGithubGraphqlLink(
            accountsByToken: accountsByToken,
            onOperation: onOperation,
            operationError: operationError,
          ),
        ),
    cache: GraphQLCache(store: InMemoryStore()),
  );
}

class _FakeGithubGraphqlLink extends Link {
  final Map<String, FakeGithubGraphqlAccount> accountsByToken;
  final void Function(String operationName)? onOperation;
  final GraphQLError? Function(
    String operationName,
    Map<String, dynamic> variables,
  )?
  operationError;

  _FakeGithubGraphqlLink({
    required this.accountsByToken,
    this.onOperation,
    this.operationError,
  });

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final operationName = _operationName(request);
    onOperation?.call(operationName);
    final injectedError = operationError?.call(
      operationName,
      request.variables,
    );
    if (injectedError != null) {
      yield Response(errors: [injectedError], response: const {});
      return;
    }
    final token = _tokenFromRequest(request);
    final account = token == null ? null : accountsByToken[token];

    if (account == null) {
      yield Response(
        errors: [GraphQLError(message: 'No fake account configured for token')],
        response: const {},
      );
      return;
    }

    final data = switch (operationName) {
      'UserInformation' => _userInformationData(account),
      'UserOrganizations' => _userOrganizationsData(account),
      'OwnerProjects' => _ownerProjectsData(
        account,
        request.variables['ownerId'] as String?,
      ),
      'UserProjects' => _userProjectsData(
        account,
        request.variables['login'] as String?,
      ),
      _ => null,
    };

    if (data == null) {
      yield Response(
        errors: [GraphQLError(message: 'Unsupported fake GraphQL operation')],
        response: const {},
      );
      return;
    }

    yield Response(data: data, response: data);
  }

  String? _tokenFromRequest(Request request) {
    final headers = request.context.entry<HttpLinkHeaders>()?.headers;
    final authorization = headers?['Authorization'];
    return authorization?.replaceFirst('Bearer ', '');
  }

  String _operationName(Request request) {
    final explicitName = request.operation.operationName;
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    for (final definition in request.operation.document.definitions) {
      final dynamic operationDefinition = definition;
      final dynamic nameNode = operationDefinition.name;
      final name = nameNode?.value;
      if (name is String && name.isNotEmpty) return name;
      break;
    }

    return 'anonymous';
  }
}

Map<String, Object?> _userInformationData(FakeGithubGraphqlAccount account) {
  return _withRateLimit({
    'viewer': {
      'id': account.viewer.id,
      'avatarUrl': account.viewer.avatarUrl,
      'name': account.viewer.name,
      'login': account.viewer.login,
      '__typename': 'User',
    },
  });
}

Map<String, Object?> _userOrganizationsData(FakeGithubGraphqlAccount account) {
  return _withRateLimit({
    'viewer': {
      'organizations': {
        'nodes': [
          for (final org in account.organizations)
            {'id': org.id, 'login': org.login, '__typename': 'Organization'},
        ],
        '__typename': 'OrganizationConnection',
      },
      '__typename': 'User',
    },
  });
}

Map<String, Object?> _userProjectsData(
  FakeGithubGraphqlAccount account,
  String? login,
) {
  final user = account.otherUsers
      .where((entry) => entry.login.toLowerCase() == login?.toLowerCase())
      .firstOrNull;
  return _withRateLimit({
    'user': user == null
        ? null
        : {
            'login': user.login,
            'projectsV2': {
              'nodes': [
                for (final project in user.projects)
                  {
                    'id': project.id,
                    'title': project.title,
                    'shortDescription': project.shortDescription,
                    'closed': project.closed,
                    '__typename': 'ProjectV2',
                  },
              ],
              '__typename': 'ProjectV2Connection',
            },
            '__typename': 'User',
          },
  });
}

Map<String, Object?> _ownerProjectsData(
  FakeGithubGraphqlAccount account,
  String? ownerId,
) {
  if (ownerId == null) {
    return _withRateLimit({'node': null});
  }

  if (ownerId == account.viewer.id) {
    return _withRateLimit({
      'node': {
        'projectsV2': {
          'nodes': [
            for (final project
                in account.projectsByOwnerId[ownerId] ?? const [])
              {
                'id': project.id,
                'title': project.title,
                'shortDescription': project.shortDescription,
                'closed': project.closed,
                '__typename': 'ProjectV2',
              },
          ],
          '__typename': 'ProjectV2Connection',
        },
        '__typename': 'User',
      },
    });
  }

  final org = account.organizations
      .where((entry) => entry.id == ownerId)
      .firstOrNull;
  if (org == null) {
    return _withRateLimit({'node': null});
  }

  return _withRateLimit({
    'node': {
      'projectsV2': {
        'nodes': [
          for (final project in account.projectsByOwnerId[ownerId] ?? const [])
            {
              'id': project.id,
              'title': project.title,
              'shortDescription': project.shortDescription,
              'closed': project.closed,
              '__typename': 'ProjectV2',
            },
        ],
        '__typename': 'ProjectV2Connection',
      },
      '__typename': 'Organization',
    },
  });
}

Map<String, Object?> _withRateLimit(Map<String, Object?> data) {
  return {
    ...data,
    'rateLimit': {
      'cost': 1,
      'limit': 5000,
      'remaining': 4999,
      'resetAt': '2026-04-21T08:00:00Z',
      '__typename': 'RateLimit',
    },
    '__typename': 'Query',
  };
}
