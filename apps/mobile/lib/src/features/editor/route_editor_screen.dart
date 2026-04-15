import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:splitway_core/splitway_core.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../shared/dialogs.dart';
import '../../shared/widgets/map_bottom_sheet_scaffold.dart';
import 'route_editor_controller.dart';
import 'widgets/route_editor_map_panel.dart';

class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({required this.bundle, this.editRouteId, super.key});

  final BootstrapBundle bundle;
  final String? editRouteId;

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  late final RouteEditorController _controller;

  bool get _isEditing => widget.editRouteId != null;

  @override
  void initState() {
    super.initState();
    _controller = RouteEditorController(
      repository: widget.bundle.repository,
      syncService: widget.bundle.syncService,
      editRouteId: widget.editRouteId,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeEditor() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/routes');
    }
  }

  Future<void> _showSaveDialog() async {
    final draft = await showDialog<_RouteSaveDialogResult>(
      context: context,
      builder: (dialogContext) => _RouteSaveDialog(
        isEditing: _isEditing,
        initialName: _controller.routeName,
        initialNotes: _controller.routeNotes,
        initialDifficulty: _controller.selectedDifficulty,
        initialIsClosed: _controller.isClosed,
        isClosureCandidate: _controller.isClosureCandidate,
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    _controller.updateDraft(
      name: draft.name,
      notes: draft.notes,
      difficulty: draft.difficulty,
    );
    _controller.setClosedPreference(draft.isClosed);

    final route = await _controller.saveRoute();
    if (!mounted || route == null) {
      return;
    }

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
  }

  void _handleMapTap(double latitude, double longitude) {
    if (_controller.sectorMode) {
      final added = _controller.addSectorPoint(latitude, longitude);
      if (!added && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toca más cerca de la ruta para añadir un sector'),
          ),
        );
      }
      return;
    }

    _controller.addWaypoint(latitude, longitude);
  }

  void _showPendingServerError() {
    final message = _controller.consumePendingServerErrorMessage();
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showSoftErrorSnackBar(context, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _showPendingServerError();

        if (_controller.isLoading) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Volver',
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
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back),
              onPressed: _closeEditor,
            ),
            title: Text(_isEditing ? 'Editar ruta' : 'Crear ruta'),
            actions: [
              IconButton(
                tooltip: 'Deshacer',
                icon: const Icon(Icons.undo),
                onPressed:
                    (_controller.waypoints.isEmpty &&
                        _controller.sectorPoints.isEmpty)
                    ? null
                    : _controller.undo,
              ),
              IconButton(
                tooltip: 'Guardar ruta',
                icon: const Icon(Icons.save),
                onPressed: _controller.canSave ? _showSaveDialog : null,
              ),
            ],
          ),
          body: MapBottomSheetScaffold(
            initialChildSize: 0.13,
            handleTopSpacing: 6,
            handleBottomSpacing: 6,
            compactPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            showDivider: false,
            background: RouteEditorMapPanel(
              config: widget.bundle.config,
              displayedGeometry: _controller.displayedGeometry,
              waypoints: _controller.waypoints,
              sectorPoints: _controller.sectorPoints,
              sectorMode: _controller.sectorMode,
              onMapTap: _handleMapTap,
            ),
            compactChild: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Waypoint',
                        icon: Icons.place,
                        selected: !_controller.sectorMode,
                        onPressed: () => _controller.toggleSectorMode(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeButton(
                        label: 'Sector',
                        icon: Icons.flag,
                        selected: _controller.sectorMode,
                        onPressed: () => _controller.toggleSectorMode(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            expandedChildBuilder: (scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatCard(
                      label: 'Distancia',
                      value:
                          '${_controller.totalDistanceKm().toStringAsFixed(2)} km',
                    ),
                    _StatCard(
                      label: 'Puntos',
                      value: '${_controller.waypoints.length}',
                    ),
                    _StatCard(
                      label: 'Sectores',
                      value: '${_controller.sectorPoints.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(
                        _controller.isClosed
                            ? 'Circuito cerrado'
                            : 'Ruta abierta',
                      ),
                      selected: _controller.isClosed,
                      onSelected: _controller.setClosedPreference,
                    ),
                    if (_controller.isClosureCandidate)
                      const Chip(
                        avatar: Icon(Icons.loop, size: 18),
                        label: Text('Cierre sugerido (< 30 m)'),
                      ),
                    if (_controller.isRoutingPreviewLoading)
                      const Chip(
                        avatar: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        label: Text('Ajustando por carretera'),
                      )
                    else if (_controller.routePreviewStatus ==
                            RoutePreviewStatus.error &&
                        _controller.waypoints.length >= 2)
                      const Chip(
                        avatar: Icon(Icons.warning_amber_rounded, size: 18),
                        label: Text('Preview sin Mapbox, usando trazado base'),
                      ),
                  ],
                ),
                if (_controller.waypoints.isNotEmpty ||
                    _controller.sectorPoints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._controller.waypoints.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _PointChip(
                              badgeLabel: '${entry.key + 1}',
                              title:
                                  '${entry.value.latitude.toStringAsFixed(4)}, ${entry.value.longitude.toStringAsFixed(4)}',
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        ..._controller.sectorPoints.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _PointChip(
                              badgeLabel: 'S${entry.key + 1}',
                              title:
                                  '${entry.value.latitude.toStringAsFixed(4)}, ${entry.value.longitude.toStringAsFixed(4)}',
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RouteSaveDialogResult {
  const _RouteSaveDialogResult({
    required this.name,
    required this.notes,
    required this.difficulty,
    required this.isClosed,
  });

  final String name;
  final String notes;
  final RouteDifficulty difficulty;
  final bool isClosed;
}

class _RouteSaveDialog extends StatefulWidget {
  const _RouteSaveDialog({
    required this.isEditing,
    required this.initialName,
    required this.initialNotes,
    required this.initialDifficulty,
    required this.initialIsClosed,
    required this.isClosureCandidate,
  });

  final bool isEditing;
  final String initialName;
  final String initialNotes;
  final RouteDifficulty initialDifficulty;
  final bool initialIsClosed;
  final bool isClosureCandidate;

  @override
  State<_RouteSaveDialog> createState() => _RouteSaveDialogState();
}

class _RouteSaveDialogState extends State<_RouteSaveDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late RouteDifficulty _selectedDifficulty;
  late bool _isClosed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _notesController = TextEditingController(text: widget.initialNotes);
    _selectedDifficulty = widget.initialDifficulty;
    _isClosed = widget.initialIsClosed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      _RouteSaveDialogResult(
        name: _nameController.text,
        notes: _notesController.text,
        difficulty: _selectedDifficulty,
        isClosed: _isClosed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Actualizar ruta' : 'Guardar ruta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la ruta',
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
                initialValue: _selectedDifficulty,
                decoration: const InputDecoration(labelText: 'Dificultad'),
                items: RouteDifficulty.values
                    .map(
                      (difficulty) => DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedDifficulty = value);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Circuito cerrado'),
                subtitle: widget.isClosureCandidate
                    ? const Text(
                        'Cierre sugerido: el ultimo punto esta a menos de 30 m',
                      )
                    : const Text(
                        'La ruta se guardara como abierta salvo activacion manual',
                      ),
                value: _isClosed,
                onChanged: (value) => setState(() => _isClosed = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        backgroundColor: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.outlineVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointChip extends StatelessWidget {
  const _PointChip({
    required this.badgeLabel,
    required this.title,
    required this.color,
  });

  final String badgeLabel;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          badgeLabel,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
      label: Text(title, style: const TextStyle(fontSize: 10)),
      visualDensity: VisualDensity.compact,
    );
  }
}
