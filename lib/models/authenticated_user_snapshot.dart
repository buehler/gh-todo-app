class AuthenticatedUserSnapshot {
  final String id;
  final String login;
  final String? name;
  final String avatarUrl;

  const AuthenticatedUserSnapshot({
    required this.id,
    required this.login,
    required this.name,
    required this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'login': login,
    'name': name,
    'avatarUrl': avatarUrl,
  };

  factory AuthenticatedUserSnapshot.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUserSnapshot(
      id: json['id'] as String,
      login: json['login'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }
}
