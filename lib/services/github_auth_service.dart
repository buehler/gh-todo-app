import 'dart:convert';

import 'package:gh_todos/models/authenticated_user_snapshot.dart';
import 'package:gh_todos/models/pat_auth_metadata.dart';
import 'package:http/http.dart' as http;

class InvalidGithubTokenException implements Exception {
  final String message;

  const InvalidGithubTokenException(this.message);

  @override
  String toString() => 'InvalidGithubTokenException: $message';
}

class MissingGithubScopesException implements Exception {
  final List<String> missingScopes;

  const MissingGithubScopesException(this.missingScopes);

  String get userMessage =>
      'The token is missing required scopes: ${missingScopes.join(', ')}.';

  @override
  String toString() =>
      'MissingGithubScopesException: ${missingScopes.join(', ')}';
}

class GithubAuthService {
  GithubAuthService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _userEndpoint = Uri.parse('https://api.github.com/user');

  final http.Client _client;

  Future<PatAuthMetadata> inspectToken(String token) async {
    final response = await _client.get(
      _userEndpoint,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      throw const InvalidGithubTokenException(
        'GitHub rejected the token. Check that it is a classic PAT with the required scopes.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final metadata = PatAuthMetadata(
      user: AuthenticatedUserSnapshot(
        id: (json['id'] as Object).toString(),
        login: json['login'] as String? ?? 'unknown',
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String? ?? '',
      ),
      scopes: _parseScopes(response.headers['x-oauth-scopes']),
      validatedAt: DateTime.now(),
    );

    if (!metadata.hasRequiredScopes) {
      throw MissingGithubScopesException(metadata.missingRequiredScopes);
    }

    return metadata;
  }

  List<String> _parseScopes(String? rawHeader) {
    if (rawHeader == null || rawHeader.trim().isEmpty) {
      return const [];
    }

    final scopes = rawHeader
        .split(',')
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return scopes;
  }
}
