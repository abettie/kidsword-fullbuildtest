class Post {
  final String postId;
  final String userId;
  final String nickname;
  final String mispronounced;
  final String intended;
  final String? description;
  final String createdAt;

  const Post({
    required this.postId,
    required this.userId,
    required this.nickname,
    required this.mispronounced,
    required this.intended,
    this.description,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json['postId'] as String,
        userId: json['userId'] as String,
        nickname: json['nickname'] as String? ?? '',
        mispronounced: json['mispronounced'] as String,
        intended: json['intended'] as String,
        description: json['description'] as String?,
        createdAt: json['createdAt'] as String,
      );
}
