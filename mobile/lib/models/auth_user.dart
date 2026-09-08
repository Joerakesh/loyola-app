/// Public user payload returned by the backend after Google sign-in.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.googleId,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.linkedEmails = const [],
    required this.erpLinked,
  });

  final String id;
  final String googleId;
  final String email;
  final String name;
  final String? avatarUrl;
  final List<String> linkedEmails;
  final bool erpLinked;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final linked = json['linkedEmails'];
    return AuthUser(
      id: json['id'] as String,
      googleId: json['googleId'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      linkedEmails: linked is List ? linked.whereType<String>().toList() : const [],
      erpLinked: json['erpLinked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'googleId': googleId,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'linkedEmails': linkedEmails,
      'erpLinked': erpLinked,
    };
  }
}