import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/post_card.dart';

final feedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(apiServiceProvider).getFeedPosts();
  return result.posts;
});

final myPostsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(apiServiceProvider).getMyPosts();
  return result.posts;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('kidsword'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'みんなの投稿'),
            Tab(text: '自分の投稿'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostList(provider: feedPostsProvider),
          _PostList(provider: myPostsProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PostList extends ConsumerWidget {
  final FutureProvider<List<Post>> provider;

  const _PostList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('読み込みに失敗しました', style: Theme.of(context).textTheme.bodyLarge),
            TextButton(
              onPressed: () => ref.refresh(provider),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('投稿がまだありません'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(provider),
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(post: posts[i]),
          ),
        );
      },
    );
  }
}
