import 'dart:convert';

import 'package:splitway_core/splitway_core.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class PendingSyncItem {
  const PendingSyncItem({
    required this.entityType,
    required this.entityId,
  });

  final String entityType;
  final String entityId;
}

class SplitwayLocalDatabase {
  Database? _database;

  Future<void> open() async {
    if (_database != null) {
      return;
    }

    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, 'splitway.db');

    _database = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE route_templates (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE session_runs (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            enqueued_at TEXT NOT NULL,
            PRIMARY KEY (entity_type, entity_id)
          )
        ''');
      },
    );
  }

  Future<Database> get _db async {
    await open();
    return _database!;
  }

  Future<void> saveRouteTemplate(RouteTemplate route, {bool queueSync = true}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'route_templates',
      {
        'id': route.id,
        'payload': jsonEncode(route.toJson()),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (queueSync) {
      await _enqueue('route_template', route.id);
    }
  }

  Future<List<RouteTemplate>> loadRouteTemplates() async {
    final db = await _db;
    final rows = await db.query(
      'route_templates',
      orderBy: 'updated_at DESC',
    );

    return rows
        .map(
          (row) => RouteTemplate.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveSessionRun(SessionRun session, {bool queueSync = true}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'session_runs',
      {
        'id': session.id,
        'payload': jsonEncode(session.toJson()),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (queueSync) {
      await _enqueue('session_run', session.id);
    }
  }

  Future<List<SessionRun>> loadSessionRuns() async {
    final db = await _db;
    final rows = await db.query(
      'session_runs',
      orderBy: 'updated_at DESC',
    );

    return rows
        .map(
          (row) => SessionRun.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<PendingSyncItem>> loadPendingSyncItems() async {
    final db = await _db;
    final rows = await db.query('sync_queue', orderBy: 'enqueued_at ASC');
    return rows
        .map(
          (row) => PendingSyncItem(
            entityType: row['entity_type'] as String,
            entityId: row['entity_id'] as String,
          ),
        )
        .toList();
  }

  Future<RouteTemplate?> loadRouteTemplateById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'route_templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return RouteTemplate.fromJson(
      jsonDecode(rows.single['payload'] as String) as Map<String, dynamic>,
    );
  }

  Future<SessionRun?> loadSessionRunById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'session_runs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return SessionRun.fromJson(
      jsonDecode(rows.single['payload'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> markSynced(String entityType, String entityId) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final table = entityType == 'route_template' ? 'route_templates' : 'session_runs';

    await db.update(
      table,
      {'synced_at': now},
      where: 'id = ?',
      whereArgs: [entityId],
    );

    await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );
  }

  Future<void> deleteRouteTemplate(String id) async {
    final db = await _db;
    await db.delete('route_templates', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['route_template', id],
    );
  }

  Future<List<SessionRun>> loadSessionRunsByRouteId(String routeId) async {
    final db = await _db;
    final rows = await db.query(
      'session_runs',
      orderBy: 'updated_at DESC',
    );

    return rows
        .map(
          (row) => SessionRun.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .where((session) => session.routeTemplateId == routeId)
        .toList();
  }

  Future<void> _enqueue(String entityType, String entityId) async {
    final db = await _db;
    await db.insert(
      'sync_queue',
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'enqueued_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
