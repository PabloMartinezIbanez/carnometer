import 'package:carnometer_core/carnometer_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../shared/dialogs.dart';
import '../../shared/widgets/difficulty_badge.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({
    required this.bundle,
    required this.routeId,
    super.key,
  });

  final BootstrapBundle bundle;
  final String routeId;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  RouteTemplate? _route;
  List<SessionRun> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final route = await widget.bundle.repository.loadRouteById(widget.routeId);
    final sessions = await widget.bundle.repository.loadSessionsByRouteId(widget.routeId);
    if (!mounted) return;
    setState(() {
      _route = route;
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar ruta',
      message: '¿Seguro que quieres eliminar esta ruta? Esta acción no se puede deshacer.',
    );

    if (!confirmed || !mounted) return;

    await widget.bundle.repository.deleteRoute(widget.routeId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta eliminada')),
    );
    context.go('/routes');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/routes'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final route = _route;
    if (route == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/routes'),
          ),
        ),
        body: Center(
          child: Text(
            'Ruta no encontrada',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy', 'es_ES');
    final geometry = route.effectiveGeometry;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/routes'),
        ),
        title: Text(route.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/routes/${widget.routeId}/edit');
              _loadData();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: theme.colorScheme.error),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          SizedBox(
            height: 280,
            width: double.infinity,
            child: widget.bundle.config.hasMapboxToken && geometry.isNotEmpty
                ? MapWidget(
                    key: ValueKey('route-detail-map-${widget.routeId}'),
                    styleUri: widget.bundle.config.mapboxStyleUri,
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          geometry.first.longitude,
                          geometry.first.latitude,
                        ),
                      ),
                      zoom: 13,
                    ),
                  )
                : Container(
                    color: const Color(0xFFE7DED1),
                    child: const Center(
                      child: Icon(Icons.map, size: 48, color: Colors.grey),
                    ),
                  ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Metadata
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DifficultyBadge(difficulty: route.difficulty),
                    _InfoChip(
                      icon: Icons.straighten,
                      label: '${geometry.length} puntos',
                    ),
                    _InfoChip(
                      icon: Icons.flag,
                      label: '${route.sectors.length} sectores',
                    ),
                    _InfoChip(
                      icon: route.isClosed ? Icons.loop : Icons.trending_flat,
                      label: route.isClosed ? 'Circuito' : 'Abierta',
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: dateFormat.format(route.createdAt),
                    ),
                  ],
                ),

                // Notes
                if (route.notes != null && route.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route.notes!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Start Stopwatch button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/routes/${widget.routeId}/stopwatch'),
                    icon: const Icon(Icons.timer),
                    label: const Text('Iniciar Cronómetro'),
                  ),
                ),

                // Session history
                if (_sessions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Historial de Tiempos',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._sessions.map((session) {
                    final duration = session.endedAt.difference(session.startedAt);
                    final sessionDateFormat = DateFormat(
                      'd MMM yyyy, HH:mm',
                      'es_ES',
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDuration(duration),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sessionDateFormat.format(session.startedAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${session.sectorSummaries.length} sectores',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
