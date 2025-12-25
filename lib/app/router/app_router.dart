import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/homes/home_page.dart';
import '../../shared/widgets/error_page.dart';

/// Go Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Add authentication redirect logic here
      // For example:
      // final isAuthenticated = ref.watch(authProvider);
      // if (!isAuthenticated && !state.location.startsWith('/login')) {
      //   return '/login';
      // }
      return null;
    },
    routes: [
      // Main routes
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          // Add nested routes here
        ],
      ),

      // Add other routes here
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // 404 Route
      GoRoute(
        path: '/404',
        name: 'notFound',
        builder: (context, state) => const NotFoundPage(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => NotFoundPage(error: state.error),

    // Navigation configuration
    navigatorKey: GlobalKey<NavigatorState>(),
  );
});