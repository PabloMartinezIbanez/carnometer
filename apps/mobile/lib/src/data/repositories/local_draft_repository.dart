import 'dart:math';

import 'package:carnometer_core/carnometer_core.dart';

import '../local/carnometer_local_database.dart';

class LocalDraftRepository {
  LocalDraftRepository({
    required this.database,
    required this.installId,
  });

  final CarnometerLocalDatabase database;
  final String installId;

  static final _random = Random();
  static int _counter = 0;

  Future<List<RouteTemplate>> loadRoutes() => database.loadRouteTemplates();

  Future<List<SessionRun>> loadSessions() => database.loadSessionRuns();

  Future<void> saveRoute(RouteTemplate route) => database.saveRouteTemplate(route);

  Future<void> saveSession(SessionRun session) => database.saveSessionRun(session);

  Future<void> deleteRoute(String id) => database.deleteRouteTemplate(id);

  Future<List<SessionRun>> loadSessionsByRouteId(String routeId) =>
      database.loadSessionRunsByRouteId(routeId);

  Future<RouteTemplate?> loadRouteById(String id) =>
      database.loadRouteTemplateById(id);

  String createId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(16, '0');
    _counter = (_counter + 1) & 0xFFFF;
    final counterHex = _counter.toRadixString(16).padLeft(4, '0');
    final randomHex = _random.nextInt(0xFFFFFFFF)
        .toRadixString(16)
        .padLeft(8, '0');
    final raw = '$timestamp$counterHex$randomHex'.padRight(32, '0').substring(0, 32);
    return '${raw.substring(0, 8)}-'
        '${raw.substring(8, 12)}-'
        '${raw.substring(12, 16)}-'
        '${raw.substring(16, 20)}-'
        '${raw.substring(20, 32)}';
  }
}
