import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/user.dart';
import 'auth_service.dart';

// APIエンドポイントは環境変数または定数で管理
// 本番デプロイ後にterraform outputのapi_endpointに置き換える
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://REPLACE_WITH_API_ENDPOINT',
);

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class ApiService {
  final AuthService _authService;
  late final Dio _dio;

  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<User?> getMyProfile() async {
    try {
      final res = await _dio.get('/users/me');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<User> updateProfile(String nickname) async {
    final res = await _dio.put('/users/me', data: {'nickname': nickname});
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Post> createPost({
    required String mispronounced,
    required String intended,
    String? description,
  }) async {
    final res = await _dio.post('/posts', data: {
      'mispronounced': mispronounced,
      'intended': intended,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<({List<Post> posts, String? nextToken})> getMyPosts({
    int limit = 20,
    String? nextToken,
  }) async {
    final res = await _dio.get('/posts/me', queryParameters: {
      'limit': limit,
      'nextToken': nextToken,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      posts: (data['posts'] as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextToken: data['nextToken'] as String?,
    );
  }

  Future<({List<Post> posts, String? nextToken})> getFeedPosts({
    int limit = 20,
    String? nextToken,
  }) async {
    final res = await _dio.get('/posts', queryParameters: {
      'limit': limit,
      'nextToken': nextToken,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      posts: (data['posts'] as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextToken: data['nextToken'] as String?,
    );
  }
}
