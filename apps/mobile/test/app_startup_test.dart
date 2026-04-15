import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitway_mobile/app.dart';
import 'package:splitway_mobile/src/bootstrap/app_bootstrap.dart';
import 'package:splitway_mobile/src/config/app_config.dart';
import 'package:splitway_mobile/src/data/local/splitway_local_database.dart';
import 'package:splitway_mobile/src/data/repositories/local_draft_repository.dart';
import 'package:splitway_mobile/src/data/repositories/supabase_sync_service.dart';
import 'package:splitway_mobile/src/shared/server_connection_error.dart';

void main() {
  testWidgets(
    'shows a retry screen when startup cannot connect to the server',
    (tester) async {
      var attempts = 0;

      await tester.pumpWidget(
        SplitwayApp(
          bootstrapper: () async {
            attempts++;
            if (attempts == 1) {
              throw const ServerConnectionException();
            }
            return _buildBundle();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se puede conectar con el servidor'), findsOneWidget);
      expect(
        find.text('Comprueba tu conexión de datos y vuelve a intentarlo.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reintentar'));
      await tester.pump();
      expect(find.text('Arrancando Splitway'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
      expect(attempts, 2);
    },
  );
}

BootstrapBundle _buildBundle() {
  final database = _FakeSplitwayLocalDatabase();
  final repository = LocalDraftRepository(
    database: database,
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
  @override
  Future<void> open() async {}
}
