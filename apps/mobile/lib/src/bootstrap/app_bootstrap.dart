import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../data/demo/demo_seed.dart';
import '../data/local/splitway_local_database.dart';
import '../data/repositories/local_draft_repository.dart';
import '../data/repositories/supabase_sync_service.dart';

class BootstrapBundle {
  const BootstrapBundle({
    required this.config,
    required this.repository,
    required this.syncService,
    required this.installId,
    required this.isSupabaseEnabled,
  });

  final AppConfig config;
  final LocalDraftRepository repository;
  final SupabaseSyncService syncService;
  final String installId;
  final bool isSupabaseEnabled;
}

class AppBootstrap {
  static Future<BootstrapBundle> initialize() async {
    final config = AppConfig.fromEnvironment();
    final database = SplitwayLocalDatabase();
    await database.open();

    if (config.hasMapboxToken) {
      MapboxOptions.setAccessToken(config.mapboxAccessToken);
    }

    SupabaseClient? client;
    var installId = 'local-demo-installation';

    if (config.hasSupabase) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );

      client = Supabase.instance.client;

      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }

      installId = client.auth.currentUser?.id ?? installId;
    }

    final repository = LocalDraftRepository(
      database: database,
      installId: installId,
    );

    await DemoSeed.seedIfEmpty(repository);

    final syncService = SupabaseSyncService(
      client: client,
      mapboxBaseUrl: config.mapboxBaseUrl,
    );

    if (client != null) {
      try {
        await syncService.syncPending(database, installId: installId);
      } on PostgrestException catch (error) {
        debugPrint('Supabase sync skipped during bootstrap: ${error.message}');
      }
    }

    return BootstrapBundle(
      config: config,
      repository: repository,
      syncService: syncService,
      installId: installId,
      isSupabaseEnabled: client != null,
    );
  }
}
