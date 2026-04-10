import 'package:carnometer_core/carnometer_core.dart';

import '../local/carnometer_local_database.dart';

class LocalDraftRepository {
  const LocalDraftRepository({
    required this.database,
    required this.installId,
  });

  final CarnometerLocalDatabase database;
  final String installId;

  Future<List<RouteTemplate>> loadRoutes() => database.loadRouteTemplates();

  Future<List<SessionRun>> loadSessions() => database.loadSessionRuns();

  Future<void> saveRoute(RouteTemplate route) => database.saveRouteTemplate(route);

  Future<void> saveSession(SessionRun session) => database.saveSessionRun(session);

  String createId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(16, '0');
    final prefixHash = prefix.codeUnits
        .fold<int>(0, (accumulator, value) => ((accumulator * 31) + value) & 0xFFFFFFFF)
        .toRadixString(16)
        .padLeft(8, '0');
    final raw = '$timestamp$prefixHash$timestamp'.padRight(32, '0').substring(0, 32);
    return '${raw.substring(0, 8)}-'
        '${raw.substring(8, 12)}-'
        '${raw.substring(12, 16)}-'
        '${raw.substring(16, 20)}-'
        '${raw.substring(20, 32)}';
  }
}
