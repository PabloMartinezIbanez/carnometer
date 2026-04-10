import 'package:carnometer_core/carnometer_core.dart';
import 'package:test/test.dart';

void main() {
  group('RouteTemplate', () {
    test('prefers snapped geometry when available', () {
      final route = RouteTemplate(
        id: 'route-1',
        name: 'Madrid ring',
        isClosed: true,
        rawGeometry: const [
          GeoPoint(latitude: 40.0, longitude: -3.7),
          GeoPoint(latitude: 40.1, longitude: -3.6),
        ],
        snappedGeometry: const [
          GeoPoint(latitude: 40.0, longitude: -3.71),
          GeoPoint(latitude: 40.1, longitude: -3.61),
        ],
        startFinishGate: GateDefinition(
          id: 'start-finish',
          label: 'Start / finish',
          start: const GeoPoint(latitude: 40.0, longitude: -3.705),
          end: const GeoPoint(latitude: 40.0, longitude: -3.695),
        ),
        sectors: const [],
        notes: 'Test route',
        createdAt: DateTime.utc(2026, 4, 10),
      );

      expect(route.effectiveGeometry, hasLength(2));
      expect(route.effectiveGeometry.first.longitude, closeTo(-3.71, 0.0001));
    });
  });
}
