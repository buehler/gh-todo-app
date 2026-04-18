import 'package:gh_todos/models/authenticated_user_snapshot.dart';

class PatAuthMetadata {
  static const requiredScopes = ['project', 'repo', 'read:org'];
  static const optionalScopes = <String>[];

  final AuthenticatedUserSnapshot user;
  final List<String> scopes;
  final DateTime validatedAt;

  const PatAuthMetadata({
    required this.user,
    required this.scopes,
    required this.validatedAt,
  });

  List<String> get normalizedScopes => [...scopes]..sort();

  List<String> get missingRequiredScopes => [
    for (final scope in requiredScopes)
      if (!scopes.contains(scope)) scope,
  ];

  bool get hasRequiredScopes => missingRequiredScopes.isEmpty;

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'scopes': scopes,
    'validatedAt': validatedAt.toIso8601String(),
  };

  factory PatAuthMetadata.fromJson(Map<String, dynamic> json) {
    return PatAuthMetadata(
      user: AuthenticatedUserSnapshot.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
      scopes: (json['scopes'] as List<dynamic>? ?? const [])
          .map((value) => value as String)
          .toList(),
      validatedAt: DateTime.parse(json['validatedAt'] as String),
    );
  }
}
