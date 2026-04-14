import 'gate_definition.dart';

class SectorDefinition {
  const SectorDefinition({
    required this.id,
    required this.routeTemplateId,
    required this.order,
    required this.label,
    required this.gate,
    this.directionHint,
  });

  final String id;
  final String routeTemplateId;
  final int order;
  final String label;
  final GateDefinition gate;
  final String? directionHint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeTemplateId': routeTemplateId,
        'order': order,
        'label': label,
        'gate': gate.toJson(),
        'directionHint': directionHint,
      };

  factory SectorDefinition.fromJson(Map<String, dynamic> json) => SectorDefinition(
        id: json['id'] as String,
        routeTemplateId: json['routeTemplateId'] as String,
        order: (json['order'] as num).toInt(),
        label: json['label'] as String,
        gate: GateDefinition.fromJson(json['gate'] as Map<String, dynamic>),
        directionHint: json['directionHint'] as String?,
      );
}
