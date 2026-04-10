import 'gate_definition.dart';
import 'geo_point.dart';
import 'sector_definition.dart';

class RouteTemplate {
  RouteTemplate({
    required this.id,
    required this.name,
    required this.isClosed,
    required this.rawGeometry,
    required this.startFinishGate,
    required List<SectorDefinition> sectors,
    required this.createdAt,
    this.snappedGeometry,
    this.notes,
  }) : sectors = List.unmodifiable(
          [...sectors]..sort((left, right) => left.order.compareTo(right.order)),
        );

  final String id;
  final String name;
  final bool isClosed;
  final List<GeoPoint> rawGeometry;
  final List<GeoPoint>? snappedGeometry;
  final GateDefinition startFinishGate;
  final List<SectorDefinition> sectors;
  final String? notes;
  final DateTime createdAt;

  List<GeoPoint> get effectiveGeometry => snappedGeometry ?? rawGeometry;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isClosed': isClosed,
        'rawGeometry': rawGeometry.map((point) => point.toJson()).toList(),
        'snappedGeometry': snappedGeometry?.map((point) => point.toJson()).toList(),
        'startFinishGate': startFinishGate.toJson(),
        'sectors': sectors.map((sector) => sector.toJson()).toList(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RouteTemplate.fromJson(Map<String, dynamic> json) => RouteTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        isClosed: json['isClosed'] as bool,
        rawGeometry: (json['rawGeometry'] as List<dynamic>)
            .map((item) => GeoPoint.fromJson(item as Map<String, dynamic>))
            .toList(),
        snappedGeometry: (json['snappedGeometry'] as List<dynamic>?)
            ?.map((item) => GeoPoint.fromJson(item as Map<String, dynamic>))
            .toList(),
        startFinishGate: GateDefinition.fromJson(
          json['startFinishGate'] as Map<String, dynamic>,
        ),
        sectors: (json['sectors'] as List<dynamic>)
            .map((item) => SectorDefinition.fromJson(item as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
