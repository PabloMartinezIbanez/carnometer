class SectorSummary {
  const SectorSummary({
    required this.sectorId,
    required this.label,
    required this.order,
    required this.duration,
    required this.crossedAt,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    this.lapNumber,
  });

  final String sectorId;
  final String label;
  final int order;
  final int? lapNumber;
  final Duration duration;
  final DateTime crossedAt;
  final double averageSpeedKmh;
  final double maxSpeedKmh;

  Map<String, dynamic> toJson() => {
        'sectorId': sectorId,
        'label': label,
        'order': order,
        'lapNumber': lapNumber,
        'durationMs': duration.inMilliseconds,
        'crossedAt': crossedAt.toIso8601String(),
        'averageSpeedKmh': averageSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
      };

  factory SectorSummary.fromJson(Map<String, dynamic> json) => SectorSummary(
        sectorId: json['sectorId'] as String,
        label: json['label'] as String,
        order: (json['order'] as num).toInt(),
        lapNumber: (json['lapNumber'] as num?)?.toInt(),
        duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
        crossedAt: DateTime.parse(json['crossedAt'] as String),
        averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      );
}
