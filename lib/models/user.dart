// lib/models/user.dart
class User {
  final String id;
  final String username;
  final String? avatarUrl; // 可选，用户头像URL

  User({required this.id, required this.username, this.avatarUrl});

  // 从 JSON 反序列化
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
    );
  }

  // 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
    };
  }
}
