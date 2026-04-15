import 'package:flutter/material.dart';

class MapBottomSheetScaffold extends StatefulWidget {
  const MapBottomSheetScaffold({
    required this.background,
    required this.compactChild,
    required this.expandedChildBuilder,
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
  final Widget Function(ScrollController scrollController) expandedChildBuilder;
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
  late double _currentExtent;

  @override
  void initState() {
    super.initState();
    _currentExtent = widget.initialChildSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showExpandedContent =
        _currentExtent > widget.initialChildSize + 0.005;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: widget.background),
        Positioned.fill(
          child: NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if ((_currentExtent - notification.extent).abs() > 0.0001) {
                setState(() {
                  _currentExtent = notification.extent;
                });
              }
              return false;
            },
            child: DraggableScrollableSheet(
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
                        if (showExpandedContent)
                          Expanded(
                            child: widget.expandedChildBuilder(
                              scrollController,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
