import 'package:carnometer_core/carnometer_core.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../bootstrap/app_bootstrap.dart';

class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({
    required this.bundle,
    super.key,
  });

  final BootstrapBundle bundle;

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  late Future<List<RouteTemplate>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = widget.bundle.repository.loadRoutes();
  }

  Future<void> _refresh() async {
    setState(() {
      _routesFuture = widget.bundle.repository.loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: MapLibreMap(
                styleString: widget.bundle.config.mapStyleUrl,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(40.4168, -3.7038),
                  zoom: 10.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editor de ruta PoC',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La base ya deja preparado el lienzo del mapa, el guardado local y el punto de integración para snap-to-road. '
                    'En esta primera iteración del repo se incluye una ruta demo para poder probar sesiones y sincronización sin depender todavía del editor gestual completo.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(label: Text('MapLibre + OSM')),
                      Chip(label: Text('Rutas locales')),
                      Chip(label: Text('Snap opcional')),
                      Chip(label: Text('Sectores por puertas')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rutas guardadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<RouteTemplate>>(
            future: _routesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final routes = snapshot.requireData;
              return Column(
                children: routes
                    .map(
                      (route) => Card(
                        child: ListTile(
                          title: Text(route.name),
                          subtitle: Text(
                            '${route.isClosed ? 'Circuito cerrado' : 'Ruta abierta'} · '
                            '${route.sectors.length} sectores · '
                            '${route.effectiveGeometry.length} puntos',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
