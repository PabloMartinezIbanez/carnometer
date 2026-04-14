import 'package:splitway_core/splitway_core.dart';
import 'package:splitway_mobile/src/bootstrap/app_bootstrap.dart';
import 'package:splitway_mobile/src/config/app_config.dart';
import 'package:splitway_mobile/src/data/local/splitway_local_database.dart';
import 'package:splitway_mobile/src/data/repositories/local_draft_repository.dart';
import 'package:splitway_mobile/src/data/repositories/supabase_sync_service.dart';
import 'package:splitway_mobile/src/features/editor/route_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('save button is disabled until 2+ waypoints are added', (tester) async {
    final database = _FakeSplitwayLocalDatabase();
    final bundle = _buildBundle(database: database);

    await tester.pumpWidget(
      MaterialApp(
        home: RouteEditorScreen(bundle: bundle),
      ),
    );
    await tester.pumpAndSettle();

    // The save icon button should be disabled when no waypoints exist
    final saveButton = find.byIcon(Icons.save);
    expect(saveButton, findsOneWidget);

    // Find the IconButton wrapping the save icon
    final iconButton = tester.widget<IconButton>(
      find.ancestor(of: saveButton, matching: find.byType(IconButton)),
    );
    expect(iconButton.onPressed, isNull, reason: 'Save should be disabled with no waypoints');
  });
}

BootstrapBundle _buildBundle({
  _FakeSplitwayLocalDatabase? database,
}) {
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

class _FakeSplitwayLocalDatabase extends SplitwayLocalDatabase {
  final List<RouteTemplate> savedRoutes = [];

  @override
  Future<void> open() async {}

  @override
  Future<void> saveRouteTemplate(RouteTemplate route, {bool queueSync = true}) async {
    savedRoutes.removeWhere((item) => item.id == route.id);
    savedRoutes.insert(0, route);
  }

  @override
  Future<List<RouteTemplate>> loadRouteTemplates() async => List.unmodifiable(savedRoutes);
}
