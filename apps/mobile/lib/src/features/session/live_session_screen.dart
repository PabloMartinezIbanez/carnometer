import 'dart:async';

import 'package:splitway_core/splitway_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../services/tracking/live_tracking_controller.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({
    required this.bundle,
    required this.routeId,
    super.key,
  });

  final BootstrapBundle bundle;
  final String routeId;

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

enum _SessionState { idle, running, paused, finished }

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  RouteTemplate? _route;
  LiveTrackingController? _controller;
  bool _loading = true;

  _SessionState _sessionState = _SessionState.idle;

  // Timer state
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  Duration _elapsed = Duration.zero;

  // Manual sector splits
  final List<Duration> _manualSectorTimes = [];
  Duration _lastSectorMark = Duration.zero;

  // GPS speed
  double _currentSpeedKmh = 0;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _controller?.stopGpsTracking();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    final route = await widget.bundle.repository.loadRouteById(widget.routeId);
    if (!mounted) return;

    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta no encontrada')),
      );
      context.pop();
      return;
    }

    setState(() {
      _route = route;
      _controller = LiveTrackingController(route: route);
      _loading = false;
    });
  }

  void _handleStart() {
    _stopwatch.start();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });

    // Start GPS tracking
    _controller?.startGpsTracking().catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS: $error')),
        );
      }
    });

    _controller?.addListener(_onTrackingUpdate);

    setState(() {
      _sessionState = _SessionState.running;
    });
  }

  void _handlePause() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    _controller?.stopGpsTracking();

    setState(() {
      _sessionState = _SessionState.paused;
    });
  }

  void _handleResume() {
    _stopwatch.start();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });

    _controller?.startGpsTracking().catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS: $error')),
        );
      }
    });

    setState(() {
      _sessionState = _SessionState.running;
    });
  }

  void _handleSector() {
    final sectorTime = _elapsed - _lastSectorMark;
    setState(() {
      _manualSectorTimes.add(sectorTime);
      _lastSectorMark = _elapsed;
    });
  }

  void _handleFinish() {
    // Record last sector
    final lastSectorTime = _elapsed - _lastSectorMark;
    _manualSectorTimes.add(lastSectorTime);

    _stopwatch.stop();
    _uiTimer?.cancel();
    _controller?.stopGpsTracking();

    setState(() {
      _sessionState = _SessionState.finished;
    });
  }

  Future<void> _handleSave() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final session = controller.buildCompletedSession(
        sessionId: widget.bundle.repository.createId('session'),
        installId: widget.bundle.installId,
      );
      await widget.bundle.repository.saveSession(session);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión guardada')),
      );
      context.go('/routes/${widget.routeId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _handleDemoLap() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.simulateDemoLap();
    final session = controller.buildCompletedSession(
      sessionId: widget.bundle.repository.createId('session'),
      installId: widget.bundle.installId,
    );
    await widget.bundle.repository.saveSession(session);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo lap guardada')),
    );
    context.go('/routes/${widget.routeId}');
  }

  void _onTrackingUpdate() {
    final snapshot = _controller?.snapshot;
    if (snapshot == null) return;

    final points = snapshot.telemetryPoints;
    if (points.isNotEmpty) {
      final lastSpeed = points.last.speedMps * 3.6;
      setState(() {
        _currentSpeedKmh = lastSpeed;
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final ms = (d.inMilliseconds % 1000) ~/ 10;
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
            onPressed: () => context.pop(),
          ),
          title: const Text('Cargando...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final route = _route!;
    final snapshot = _controller?.snapshot;
    final geometry = route.effectiveGeometry;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(route.name),
      ),
      body: Column(
        children: [
          // Timer display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _formatDuration(_elapsed),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speed, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentSpeedKmh.toStringAsFixed(0)} km/h',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      'Sector ${(_manualSectorTimes.length + 1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (snapshot != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${snapshot.lapSummaries.length} vueltas',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: widget.bundle.config.hasMapboxToken && geometry.isNotEmpty
                ? MapWidget(
                    key: ValueKey('session-map-${widget.routeId}'),
                    styleUri: widget.bundle.config.mapboxStyleUri,
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          geometry.first.longitude,
                          geometry.first.latitude,
                        ),
                      ),
                      zoom: 14,
                    ),
                  )
                : Container(
                    color: const Color(0xFFE7DED1),
                    child: const Center(
                      child: Icon(Icons.map, size: 48, color: Colors.grey),
                    ),
                  ),
          ),

          // Sector splits + Controls
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Sector splits (scrollable horizontal)
                  if (_manualSectorTimes.isNotEmpty)
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        itemCount: _manualSectorTimes.length,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'S${index + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _formatDuration(_manualSectorTimes[index]),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Engine-detected sectors from tracking
                  if (snapshot != null && snapshot.sectorSummaries.isNotEmpty)
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        itemCount: snapshot.sectorSummaries.length,
                        itemBuilder: (context, index) {
                          final sector = snapshot.sectorSummaries[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sector.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                Text(
                                  _formatDuration(sector.duration),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // Live metrics row
                  if (snapshot != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          _MetricChip(
                            label: 'Distancia',
                            value: '${snapshot.distanceM.toStringAsFixed(0)} m',
                          ),
                          const SizedBox(width: 8),
                          _MetricChip(
                            label: 'V. máx',
                            value: '${snapshot.maxSpeedKmh.toStringAsFixed(1)} km/h',
                          ),
                        ],
                      ),
                    ),

                  // Control buttons
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildControls(theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return switch (_sessionState) {
      _SessionState.idle => Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _handleStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _handleDemoLap,
              icon: const Icon(Icons.science),
              label: const Text('Demo'),
            ),
          ],
        ),
      _SessionState.running => Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handlePause,
                icon: const Icon(Icons.pause),
                label: const Text('Pausar'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _handleSector,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag),
                  SizedBox(width: 4),
                  Text('Sector'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _handleFinish,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Fin'),
            ),
          ],
        ),
      _SessionState.paused => Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _handleResume,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reanudar'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _handleFinish,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Fin'),
            ),
          ],
        ),
      _SessionState.finished => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Sesión'),
          ),
        ),
    };
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
