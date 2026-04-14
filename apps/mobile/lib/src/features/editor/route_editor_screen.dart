import 'dart:math';

import 'package:splitway_core/splitway_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../bootstrap/app_bootstrap.dart';

class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({
    required this.bundle,
    this.editRouteId,
    super.key,
  });

  final BootstrapBundle bundle;
  final String? editRouteId;

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  final List<GeoPoint> _waypoints = [];
  final List<GeoPoint> _sectorPoints = [];
  RouteDifficulty _selectedDifficulty = RouteDifficulty.easy;
  bool _isClosed = false;
  bool _sectorMode = false;
  bool _isSaving = false;
  bool _loading = false;

  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotationManager? _polylineManager;

  RouteTemplate? _existingRoute;

  bool get _isEditing => widget.editRouteId != null;
  bool get _canSave => _waypoints.length >= 2 && _nameController.text.trim().isNotEmpty;

  void _closeEditor() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/routes');
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingRoute();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRoute() async {
    setState(() => _loading = true);
    final route = await widget.bundle.repository.loadRouteById(widget.editRouteId!);
    if (!mounted) return;

    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta no encontrada')),
      );
      _closeEditor();
      return;
    }

    setState(() {
      _existingRoute = route;
      _nameController.text = route.name;
      _notesController.text = route.notes ?? '';
      _selectedDifficulty = route.difficulty;
      _isClosed = route.isClosed;
      _waypoints.addAll(route.rawGeometry);
      for (final sector in route.sectors) {
        _sectorPoints.add(
          GeoPoint(
            latitude: sector.gate.start.latitude,
            longitude: sector.gate.start.longitude,
          ),
        );
      }
      _loading = false;
    });
    _refreshAnnotations();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _circleManager = await map.annotations.createCircleAnnotationManager();
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    await _refreshAnnotations();
  }

  void _onMapTap(MapContentGestureContext context) {
    final coords = context.point.coordinates;
    final lat = coords.lat.toDouble();
    final lng = coords.lng.toDouble();
    if (_sectorMode) {
      _addSectorPoint(lat, lng);
    } else {
      _addWaypoint(lat, lng);
    }
  }

  Future<void> _refreshAnnotations() async {
    final circleManager = _circleManager;
    final polylineManager = _polylineManager;
    if (circleManager == null || polylineManager == null) return;

    await circleManager.deleteAll();
    await polylineManager.deleteAll();

    // Draw waypoint circles (blue)
    final waypointCircles = _waypoints.asMap().entries.map((entry) {
      final wp = entry.value;
      return CircleAnnotationOptions(
        geometry: Point(coordinates: Position(wp.longitude, wp.latitude)),
        circleRadius: 8.0,
        circleColor: Colors.blue.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 2.0,
      );
    }).toList();

    // Draw sector circles (orange)
    final sectorCircles = _sectorPoints.map((sp) {
      return CircleAnnotationOptions(
        geometry: Point(coordinates: Position(sp.longitude, sp.latitude)),
        circleRadius: 8.0,
        circleColor: Colors.orange.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 2.0,
      );
    }).toList();

    if (waypointCircles.isNotEmpty) {
      await circleManager.createMulti(waypointCircles);
    }
    if (sectorCircles.isNotEmpty) {
      await circleManager.createMulti(sectorCircles);
    }

    // Draw polyline connecting waypoints
    if (_waypoints.length >= 2) {
      final positions = _waypoints
          .map((wp) => Position(wp.longitude, wp.latitude))
          .toList();
      await polylineManager.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: Colors.blue.value,
          lineWidth: 3.0,
        ),
      );
    }
  }

  void _addWaypoint(double latitude, double longitude) {
    setState(() {
      _waypoints.add(GeoPoint(latitude: latitude, longitude: longitude));
    });
    _refreshAnnotations();
  }

  void _addSectorPoint(double latitude, double longitude) {
    if (_waypoints.length < 2) return;

    final snapped = _nearestPointOnRoute(latitude, longitude);
    if (snapped != null) {
      setState(() {
        _sectorPoints.add(snapped);
      });
      _refreshAnnotations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toca más cerca de la ruta para añadir un sector')),
      );
    }
  }

  GeoPoint? _nearestPointOnRoute(double lat, double lng) {
    const maxDistanceM = 500.0;
    double bestDistance = double.infinity;
    GeoPoint? bestPoint;

    for (int i = 0; i < _waypoints.length - 1; i++) {
      final a = _waypoints[i];
      final b = _waypoints[i + 1];

      final projected = _projectOntoSegment(lat, lng, a, b);
      final distance = _haversineMeters(lat, lng, projected.latitude, projected.longitude);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestPoint = projected;
      }
    }

    if (bestDistance <= maxDistanceM && bestPoint != null) {
      return bestPoint;
    }
    return null;
  }

  GeoPoint _projectOntoSegment(double lat, double lng, GeoPoint a, GeoPoint b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final lenSq = dx * dx + dy * dy;

    if (lenSq == 0) return a;

    var t = ((lng - a.longitude) * dx + (lat - a.latitude) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);

    return GeoPoint(
      latitude: a.latitude + t * dy,
      longitude: a.longitude + t * dx,
    );
  }

  static double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  double _totalDistanceKm() {
    double total = 0;
    for (int i = 0; i < _waypoints.length - 1; i++) {
      total += _haversineMeters(
        _waypoints[i].latitude,
        _waypoints[i].longitude,
        _waypoints[i + 1].latitude,
        _waypoints[i + 1].longitude,
      );
    }
    return total / 1000;
  }

  void _undo() {
    setState(() {
      if (_sectorMode && _sectorPoints.isNotEmpty) {
        _sectorPoints.removeLast();
      } else if (_waypoints.isNotEmpty) {
        _waypoints.removeLast();
      }
    });
    _refreshAnnotations();
  }

  GateDefinition _buildGateFromPoint(GeoPoint point, String id, String label) {
    const offsetDeg = 0.0003;
    return GateDefinition(
      id: id,
      label: label,
      start: GeoPoint(
        latitude: point.latitude - offsetDeg,
        longitude: point.longitude - offsetDeg,
      ),
      end: GeoPoint(
        latitude: point.latitude + offsetDeg,
        longitude: point.longitude + offsetDeg,
      ),
    );
  }

  Future<void> _showSaveDialog() async {
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(_isEditing ? 'Actualizar ruta' : 'Guardar ruta'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la ruta',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduce un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RouteDifficulty>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Dificultad',
                        border: OutlineInputBorder(),
                      ),
                      items: RouteDifficulty.values
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => _selectedDifficulty = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Circuito cerrado'),
                      value: _isClosed,
                      onChanged: (value) {
                        setDialogState(() => _isClosed = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: Text(_isEditing ? 'Actualizar' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      await _saveRoute();
    }
  }

  Future<void> _saveRoute() async {
    if (_isSaving || !_canSave) return;

    setState(() => _isSaving = true);

    try {
      final routeId = _isEditing
          ? widget.editRouteId!
          : widget.bundle.repository.createId('route');

      final sectors = <SectorDefinition>[];
      for (var i = 0; i < _sectorPoints.length; i++) {
        final point = _sectorPoints[i];
        sectors.add(
          SectorDefinition(
            id: widget.bundle.repository.createId('sector'),
            routeTemplateId: routeId,
            order: i + 1,
            label: 'Sector ${i + 1}',
            gate: _buildGateFromPoint(point, 'gate-s${i + 1}', 'S${i + 1}'),
          ),
        );
      }

      final route = RouteTemplate(
        id: routeId,
        name: _nameController.text.trim(),
        difficulty: _selectedDifficulty,
        isClosed: _isClosed,
        rawGeometry: List.from(_waypoints),
        startFinishGate: _buildGateFromPoint(
          _waypoints.first,
          'start-finish',
          'Salida/Meta',
        ),
        sectors: sectors,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _existingRoute?.createdAt ?? DateTime.now(),
      );

      await widget.bundle.repository.saveRoute(route);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Ruta actualizada' : 'Ruta guardada'),
        ),
      );

      if (_isEditing) {
        _closeEditor();
      } else {
        context.go('/routes');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeEditor,
          ),
          title: const Text('Cargando...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeEditor,
        ),
        title: Text(_isEditing ? 'Editar ruta' : 'Crear ruta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: (_waypoints.isEmpty && _sectorPoints.isEmpty) ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _canSave ? _showSaveDialog : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                widget.bundle.config.hasMapboxToken
                    ? MapWidget(
                        key: const ValueKey('route-editor-mapbox-map'),
                        styleUri: widget.bundle.config.mapboxStyleUri,
                        cameraOptions: CameraOptions(
                          center: Point(
                            coordinates: _waypoints.isNotEmpty
                                ? Position(
                                    _waypoints.first.longitude,
                                    _waypoints.first.latitude,
                                  )
                                : Position(-3.7038, 40.4168),
                          ),
                          zoom: _waypoints.isNotEmpty ? 13 : 10.4,
                        ),
                        onMapCreated: _onMapCreated,
                        onTapListener: _onMapTap,
                      )
                    : Container(
                        color: const Color(0xFFE7DED1),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'Añade MAPBOX_ACCESS_TOKEN\npara ver el mapa',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                // Sector mode indicator
                if (_sectorMode)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Modo sector activo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Controls panel
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
                  // Info bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        _StatChip(
                          label: 'Distancia',
                          value: '${_totalDistanceKm().toStringAsFixed(2)} km',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Puntos',
                          value: '${_waypoints.length}',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Sectores',
                          value: '${_sectorPoints.length}',
                        ),
                      ],
                    ),
                  ),

                  // Sector mode toggle + manual add buttons
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Waypoints'),
                                icon: Icon(Icons.place),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Sectores'),
                                icon: Icon(Icons.flag),
                              ),
                            ],
                            selected: {_sectorMode},
                            onSelectionChanged: (value) {
                              setState(() => _sectorMode = value.first);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Manual add button (for demo / no-map-tap fallback)
                        IconButton.filled(
                          onPressed: _showManualCoordinateDialog,
                          icon: const Icon(Icons.add_location_alt),
                          tooltip: 'Añadir punto manual',
                        ),
                      ],
                    ),
                  ),

                  // Waypoint/Sector list (compact)
                  if (_waypoints.isNotEmpty || _sectorPoints.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          ..._waypoints.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                label: Text(
                                  '${entry.value.latitude.toStringAsFixed(4)}, ${entry.value.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          ..._sectorPoints.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.orange.shade700,
                                  child: Text(
                                    'S${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                label: Text(
                                  '${entry.value.latitude.toStringAsFixed(4)}, ${entry.value.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualCoordinateDialog() async {
    final latController = TextEditingController();
    final lngController = TextEditingController();

    // Default to Madrid center or last waypoint
    if (_waypoints.isNotEmpty) {
      final last = _waypoints.last;
      latController.text = last.latitude.toStringAsFixed(6);
      lngController.text = last.longitude.toStringAsFixed(6);
    } else {
      latController.text = '40.4168';
      lngController.text = '-3.7038';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_sectorMode ? 'Añadir sector' : 'Añadir waypoint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitud',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitud',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);
    latController.dispose();
    lngController.dispose();

    if (lat == null || lng == null ||
        lat < -90 || lat > 90 ||
        lng < -180 || lng > 180) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coordenadas inválidas')),
        );
      }
      return;
    }

    if (_sectorMode) {
      _addSectorPoint(lat, lng);
    } else {
      _addWaypoint(lat, lng);
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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
