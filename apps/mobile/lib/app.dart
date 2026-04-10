import 'package:flutter/material.dart';

import 'src/bootstrap/app_bootstrap.dart';
import 'src/features/shell/home_shell.dart';

class CarnometerApp extends StatefulWidget {
  const CarnometerApp({super.key});

  @override
  State<CarnometerApp> createState() => _CarnometerAppState();
}

class _CarnometerAppState extends State<CarnometerApp> {
  late final Future<BootstrapBundle> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = AppBootstrap.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carnometer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9A3412),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4EFE8),
        useMaterial3: true,
      ),
      home: FutureBuilder<BootstrapBundle>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _BootstrapScaffold(
              title: 'Arrancando Carnometer',
              subtitle: 'Preparando base local, mapa y sincronización opcional.',
            );
          }

          if (snapshot.hasError) {
            return _BootstrapScaffold(
              title: 'No se pudo iniciar la app',
              subtitle: snapshot.error.toString(),
            );
          }

          return HomeShell(bundle: snapshot.requireData);
        },
      ),
    );
  }
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
