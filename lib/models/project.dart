class Project {
  final String id;
  final String name;
  final String ownerLogin;

  const Project({
    required this.id,
    required this.name,
    required this.ownerLogin,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerLogin': ownerLogin,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerLogin: (json['ownerLogin'] as String?) ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
