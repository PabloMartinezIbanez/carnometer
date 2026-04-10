class TelemetryPoint {
  const TelemetryPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.accuracyM,
    required this.headingDeg,
    this.altitudeM,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double speedMps;
  final double accuracyM;
  final double headingDeg;
  final double? altitudeM;

  double get speedKmh => speedMps * 3.6;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'speedMps': speedMps,
        'accuracyM': accuracyM,
        'headingDeg': headingDeg,
        'altitudeM': altitudeM,
      };

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) => TelemetryPoint(
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        speedMps: (json['speedMps'] as num).toDouble(),
        accuracyM: (json['accuracyM'] as num).toDouble(),
        headingDeg: (json['headingDeg'] as num).toDouble(),
        altitudeM: (json['altitudeM'] as num?)?.toDouble(),
      );
}
