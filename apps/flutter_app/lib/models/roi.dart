import 'package:flutter/material.dart';

class RoiPoint {
  final double x; // 0.0 to 1.0 (normalized)
  final double y; // 0.0 to 1.0 (normalized)

  const RoiPoint({required this.x, required this.y});

  factory RoiPoint.fromJson(Map<String, dynamic> json) {
    return RoiPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  Offset toOffset(Size canvasSize) => Offset(x * canvasSize.width, y * canvasSize.height);

  static RoiPoint fromOffset(Offset offset, Size canvasSize) {
    return RoiPoint(
      x: (offset.dx / canvasSize.width).clamp(0.0, 1.0),
      y: (offset.dy / canvasSize.height).clamp(0.0, 1.0),
    );
  }
}

class RoiPolygon {
  final String id;
  final String name;
  final String zoneType; // e.g. 'cashier_desk', 'backstore_perimeter', 'fitting_room'
  final Color color;
  final List<RoiPoint> points;

  const RoiPolygon({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.color,
    required this.points,
  });

  factory RoiPolygon.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List? ?? [])
        .map((p) => RoiPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    return RoiPolygon(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Zone Polygon',
      zoneType: json['zone_type'] ?? 'custom',
      color: _parseColor(json['color']),
      points: pointsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'zone_type': zoneType,
        'color': color.value.toRadixString(16),
        'points': points.map((p) => p.toJson()).toList(),
      };

  static Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return const Color(0xFF00E5FF);
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      final hex = colorValue.replaceFirst('#', '');
      return Color(int.tryParse(hex, radix: 16) ?? 0xFF00E5FF);
    }
    return const Color(0xFF00E5FF);
  }

  RoiPolygon copyWith({
    String? id,
    String? name,
    String? zoneType,
    Color? color,
    List<RoiPoint>? points,
  }) {
    return RoiPolygon(
      id: id ?? this.id,
      name: name ?? this.name,
      zoneType: zoneType ?? this.zoneType,
      color: color ?? this.color,
      points: points ?? this.points,
    );
  }
}
