import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/app_bootstrap.dart';
import '../features/editor/route_editor_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/routes/my_routes_screen.dart';
import '../features/routes/route_detail_screen.dart';
import '../features/session/live_session_screen.dart';

GoRouter buildAppRouter(BootstrapBundle bundle) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(bundle: bundle),
      ),
      GoRoute(
        path: '/routes',
        builder: (context, state) => MyRoutesScreen(bundle: bundle),
      ),
      GoRoute(
        path: '/routes/create',
        builder: (context, state) => RouteEditorScreen(bundle: bundle),
      ),
      GoRoute(
        path: '/routes/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RouteDetailScreen(bundle: bundle, routeId: id);
        },
      ),
      GoRoute(
        path: '/routes/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RouteEditorScreen(bundle: bundle, editRouteId: id);
        },
      ),
      GoRoute(
        path: '/routes/:id/stopwatch',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LiveSessionScreen(bundle: bundle, routeId: id);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => HistoryScreen(bundle: bundle),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
