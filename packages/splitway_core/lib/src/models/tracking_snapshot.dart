import 'lap_summary.dart';
import 'sector_summary.dart';
import 'telemetry_point.dart';

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.telemetryPoints,
    required this.sectorSummaries,
    required this.lapSummaries,
    required this.distanceM,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.isLapArmed,
    required this.nextSectorIndex,
  });

  final List<TelemetryPoint> telemetryPoints;
  final List<SectorSummary> sectorSummaries;
  final List<LapSummary> lapSummaries;
  final double distanceM;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final bool isLapArmed;
  final int nextSectorIndex;
}
