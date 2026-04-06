class User {
  final String userId;
  final String nickname;
  final String createdAt;
  final String updatedAt;

  const User({
    required this.userId,
    required this.nickname,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );
}
