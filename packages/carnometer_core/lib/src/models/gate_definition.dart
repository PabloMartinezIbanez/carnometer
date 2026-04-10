import 'geo_point.dart';

class GateDefinition {
  const GateDefinition({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    this.directionHint = 'forward',
  });

  final String id;
  final String label;
  final GeoPoint start;
  final GeoPoint end;
  final String? directionHint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'start': start.toJson(),
        'end': end.toJson(),
        'directionHint': directionHint,
      };

  factory GateDefinition.fromJson(Map<String, dynamic> json) => GateDefinition(
        id: json['id'] as String,
        label: json['label'] as String,
        start: GeoPoint.fromJson(json['start'] as Map<String, dynamic>),
        end: GeoPoint.fromJson(json['end'] as Map<String, dynamic>),
        directionHint: json['directionHint'] as String?,
      );
}
