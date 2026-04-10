import 'package:flutter/material.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../editor/route_editor_screen.dart';
import '../history/history_screen.dart';
import '../session/live_session_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.bundle,
    super.key,
  });

  final BootstrapBundle bundle;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      RouteEditorScreen(bundle: widget.bundle),
      LiveSessionScreen(bundle: widget.bundle),
      HistoryScreen(bundle: widget.bundle),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnometer'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Chip(
              label: Text(
                widget.bundle.isSupabaseEnabled ? 'Supabase activo' : 'Modo local',
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) => setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route),
            label: 'Rutas',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer),
            label: 'Sesión',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
