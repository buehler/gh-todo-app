import 'package:graphql/client.dart';

class FakeGithubGraphqlAccount {
  final FakeGithubGraphqlViewer viewer;
  final List<FakeGithubGraphqlOrg> organizations;
  final Map<String, List<FakeGithubGraphqlProject>> projectsByOwnerId;

  const FakeGithubGraphqlAccount({
    required this.viewer,
    this.organizations = const [],
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
}) {
  return GraphQLClient(
    link: AuthLink(
      getToken: () async {
        final token = await readToken();
        return token == null ? null : 'Bearer $token';
      },
    ).concat(_FakeGithubGraphqlLink(accountsByToken: accountsByToken)),
    cache: GraphQLCache(store: InMemoryStore()),
  );
}

class _FakeGithubGraphqlLink extends Link {
  final Map<String, FakeGithubGraphqlAccount> accountsByToken;

  _FakeGithubGraphqlLink({required this.accountsByToken});

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final operationName = request.operation.operationName;
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
}

Map<String, Object?> _userInformationData(FakeGithubGraphqlAccount account) {
  return {
    'viewer': {
      'id': account.viewer.id,
      'avatarUrl': account.viewer.avatarUrl,
      'name': account.viewer.name,
      'login': account.viewer.login,
      '__typename': 'User',
    },
    '__typename': 'Query',
  };
}

Map<String, Object?> _userOrganizationsData(FakeGithubGraphqlAccount account) {
  return {
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
    '__typename': 'Query',
  };
}

Map<String, Object?> _ownerProjectsData(
  FakeGithubGraphqlAccount account,
  String? ownerId,
) {
  if (ownerId == null) {
    return {'node': null, '__typename': 'Query'};
  }

  if (ownerId == account.viewer.id) {
    return {
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
      '__typename': 'Query',
    };
  }

  final org = account.organizations
      .where((entry) => entry.id == ownerId)
      .firstOrNull;
  if (org == null) {
    return {'node': null, '__typename': 'Query'};
  }

  return {
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
    '__typename': 'Query',
  };
}
