import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/nickname_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: KidswordApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final user = authState.valueOrNull;

      if (user == null) {
        return state.matchedLocation == '/login' ? null : '/login';
      }

      if (state.matchedLocation == '/login' || state.matchedLocation == '/') {
        try {
          final apiService = ref.read(apiServiceProvider);
          final profile = await apiService.getMyProfile();
          if (profile == null) return '/nickname';
          return '/home';
        } catch (_) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/nickname', builder: (context, state) => const NicknameScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/post/new', builder: (context, state) => const PostFormScreen()),
    ],
  );
});

class KidswordApp extends ConsumerWidget {
  const KidswordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'kidsword',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
