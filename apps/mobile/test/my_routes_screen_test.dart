import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:splitway_core/splitway_core.dart';
import 'package:splitway_mobile/src/bootstrap/app_bootstrap.dart';
import 'package:splitway_mobile/src/config/app_config.dart';
import 'package:splitway_mobile/src/data/local/splitway_local_database.dart';
import 'package:splitway_mobile/src/data/repositories/local_draft_repository.dart';
import 'package:splitway_mobile/src/data/repositories/supabase_sync_service.dart';
import 'package:splitway_mobile/src/features/routes/my_routes_screen.dart';

void main() {
  testWidgets('shows saved route distance in kilometers instead of point count', (
    tester,
  ) async {
    await initializeDateFormatting('es_ES');
    final database = _FakeSplitwayLocalDatabase()
      ..savedRoutes.add(_sampleRoute());
    final bundle = _buildBundle(database: database);

    await tester.pumpWidget(
      MaterialApp(home: MyRoutesScreen(bundle: bundle)),
    );
    await tester.pumpAndSettle();

    expect(find.text('111.19 km'), findsOneWidget);
    expect(find.textContaining('puntos'), findsNothing);
  });
}

BootstrapBundle _buildBundle({_FakeSplitwayLocalDatabase? database}) {
  final localDatabase = database ?? _FakeSplitwayLocalDatabase();
  final repository = LocalDraftRepository(
    database: localDatabase,
    installId: 'test-installation',
  );

  return BootstrapBundle(
    config: const AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      mapboxAccessToken: '',
      mapboxStyleUri: 'mapbox://styles/mapbox/streets-v12',
      mapboxBaseUrl: 'https://api.mapbox.com',
    ),
    repository: repository,
    syncService: const SupabaseSyncService(
      client: null,
      mapboxBaseUrl: 'https://api.mapbox.com',
    ),
    installId: 'test-installation',
    isSupabaseEnabled: false,
  );
}

RouteTemplate _sampleRoute() {
  return RouteTemplate(
    id: 'route-1',
    name: 'Ruta larga',
    difficulty: RouteDifficulty.medium,
    isClosed: false,
    rawGeometry: const [
      GeoPoint(latitude: 0, longitude: 0),
      GeoPoint(latitude: 0, longitude: 1),
    ],
    startFinishGate: const GateDefinition(
      id: 'gate-1',
      label: 'Salida/Meta',
      start: GeoPoint(latitude: 0, longitude: 0),
      end: GeoPoint(latitude: 0, longitude: 0.0001),
    ),
    sectors: const [],
    createdAt: DateTime(2026, 4, 15),
  );
}

class _FakeSplitwayLocalDatabase extends SplitwayLocalDatabase {
  final List<RouteTemplate> savedRoutes = [];

  @override
  Future<void> open() async {}

  @override
  Future<List<RouteTemplate>> loadRouteTemplates() async =>
      List.unmodifiable(savedRoutes);
}
