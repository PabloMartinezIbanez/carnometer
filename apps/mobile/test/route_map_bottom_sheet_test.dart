import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitway_mobile/src/shared/widgets/map_bottom_sheet_scaffold.dart';

void main() {
  testWidgets('shows compact content before sheet expansion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapBottomSheetScaffold(
          background: const ColoredBox(color: Colors.blue),
          compactChild: const Text('Acciones compactas'),
          expandedChild: const Text('Metricas expandidas'),
        ),
      ),
    );

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.byKey(MapBottomSheetScaffold.dragHandleKey), findsOneWidget);
    expect(find.text('Acciones compactas'), findsOneWidget);
  });

  testWidgets('expands when dragging from compact panel content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapBottomSheetScaffold(
            background: const ColoredBox(color: Colors.blue),
            compactChild: const SizedBox(
              height: 80,
              child: Center(child: Text('Panel compacto')),
            ),
            expandedChild: const Text('Metricas expandidas'),
          ),
        ),
      ),
    );

    final compactFinder = find.text('Panel compacto');
    final beforeDragHeight = tester.getRect(compactFinder).top;

    await tester.drag(compactFinder, const Offset(0, -250));
    await tester.pumpAndSettle();

    final afterDragHeight = tester.getRect(compactFinder).top;
    expect(afterDragHeight, lessThan(beforeDragHeight));
    expect(find.text('Metricas expandidas'), findsOneWidget);
  });
}
