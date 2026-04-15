import 'package:flutter/material.dart';

import 'src/bootstrap/app_bootstrap.dart';
import 'src/routing/app_router.dart';
import 'src/shared/server_connection_error.dart';

typedef BootstrapLoader = Future<BootstrapBundle> Function();

class SplitwayApp extends StatefulWidget {
  const SplitwayApp({
    super.key,
    this.bootstrapper = AppBootstrap.initialize,
  });

  final BootstrapLoader bootstrapper;

  @override
  State<SplitwayApp> createState() => _SplitwayAppState();
}

class _SplitwayAppState extends State<SplitwayApp> {
  late Future<BootstrapBundle> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = widget.bootstrapper();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapBundle>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildShell(
            home: const _BootstrapScaffold(
              title: 'Arrancando Splitway',
              subtitle: 'Preparando base local, mapa y sincronización opcional.',
            ),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error!;
          if (error is ServerConnectionException) {
            return _buildShell(
              home: _ServerConnectionScaffold(
                onRetry: _retryBootstrap,
              ),
            );
          }

          return _buildShell(
            home: _BootstrapScaffold(
              title: 'No se pudo iniciar la app',
              subtitle: error.toString(),
            ),
          );
        }

        final router = buildAppRouter(snapshot.requireData);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Splitway',
          theme: _theme,
          routerConfig: router,
        );
      },
    );
  }

  Widget _buildShell({required Widget home}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Splitway',
      theme: _theme,
      home: home,
    );
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = widget.bootstrapper();
    });
  }

  static final _theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9A3412),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4EFE8),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFE8DDD3),
      selectedColor: const Color(0xFFF7D9C6),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD5C6BA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9A3412), width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    useMaterial3: true,
  );
}

class _BootstrapScaffold extends StatelessWidget {
  const _BootstrapScaffold({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerConnectionScaffold extends StatelessWidget {
  const _ServerConnectionScaffold({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  'No se puede conectar con el servidor',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Comprueba tu conexión de datos y vuelve a intentarlo.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
