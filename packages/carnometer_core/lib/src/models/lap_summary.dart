class LapSummary {
  const LapSummary({
    required this.lapNumber,
    required this.duration,
    required this.completedAt,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
  });

  final int lapNumber;
  final Duration duration;
  final DateTime completedAt;
  final double averageSpeedKmh;
  final double maxSpeedKmh;

  Map<String, dynamic> toJson() => {
        'lapNumber': lapNumber,
        'durationMs': duration.inMilliseconds,
        'completedAt': completedAt.toIso8601String(),
        'averageSpeedKmh': averageSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
      };

  factory LapSummary.fromJson(Map<String, dynamic> json) => LapSummary(
        lapNumber: (json['lapNumber'] as num).toInt(),
        duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
        completedAt: DateTime.parse(json['completedAt'] as String),
        averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      );
}
