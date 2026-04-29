import 'package:flutter/material.dart';

class MapBottomSheetScaffold extends StatefulWidget {
  const MapBottomSheetScaffold({
    required this.background,
    required this.compactChild,
    required this.expandedChild,
    this.initialChildSize = 0.24,
    this.maxChildSize = 0.9,
    this.handleTopSpacing = 8,
    this.handleBottomSpacing = 8,
    this.compactPadding = const EdgeInsets.fromLTRB(16, 0, 16, 4),
    this.showDivider = true,
    super.key,
  }) : assert(initialChildSize > 0 && initialChildSize < 1),
       assert(maxChildSize > initialChildSize && maxChildSize <= 1);

  static const dragHandleKey = Key('map-bottom-sheet-drag-handle');

  final Widget background;
  final Widget compactChild;
  final Widget expandedChild;
  final double initialChildSize;
  final double maxChildSize;
  final double handleTopSpacing;
  final double handleBottomSpacing;
  final EdgeInsets compactPadding;
  final bool showDivider;

  @override
  State<MapBottomSheetScaffold> createState() => _MapBottomSheetScaffoldState();
}

class _MapBottomSheetScaffoldState extends State<MapBottomSheetScaffold> {
  final _sheetController = DraggableScrollableController();
  late double _currentExtent;
  double? _pointerDownDy;

  @override
  void initState() {
    super.initState();
    _currentExtent = widget.initialChildSize;
    _sheetController.addListener(_onExtentChanged);
  }

  @override
  void dispose() {
    _sheetController
      ..removeListener(_onExtentChanged)
      ..dispose();
    super.dispose();
  }

  void _onExtentChanged() {
    if (!_sheetController.isAttached) return;
    final size = _sheetController.size;
    if ((_currentExtent - size).abs() > 0.0001) {
      setState(() => _currentExtent = size);
    }
  }

  bool get _isCompact => _currentExtent <= widget.initialChildSize + 0.01;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownDy = event.position.dy;
  }

  void _onPointerUp(PointerUpEvent event) {
    final startDy = _pointerDownDy;
    _pointerDownDy = null;
    if (startDy == null || !_isCompact || !_sheetController.isAttached) return;
    if (event.position.dy - startDy < -10) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetController.isAttached) {
          _sheetController.animateTo(
            widget.maxChildSize,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownDy = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showExpandedContent = _currentExtent > widget.initialChildSize + 0.005;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: widget.background),
        Positioned.fill(
          child: DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: widget.initialChildSize,
            minChildSize: widget.initialChildSize,
            maxChildSize: widget.maxChildSize,
            snap: true,
            snapSizes: [widget.initialChildSize, widget.maxChildSize],
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Listener(
                          onPointerDown: _onPointerDown,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerCancel,
                          child: Column(
                            children: [
                              SizedBox(height: widget.handleTopSpacing),
                              Container(
                                key: MapBottomSheetScaffold.dragHandleKey,
                                width: 48,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              SizedBox(height: widget.handleBottomSpacing),
                              Padding(
                                padding: widget.compactPadding,
                                child: widget.compactChild,
                              ),
                              if (showExpandedContent && widget.showDivider)
                                const Divider(height: 1),
                            ],
                          ),
                        ),
                      ),
                      if (showExpandedContent)
                        SliverToBoxAdapter(child: widget.expandedChild),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
