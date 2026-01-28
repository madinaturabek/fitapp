import '../../domain/entities/route_point.dart';

class RoutePointModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  RoutePointModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Из JSON (для локального хранилища)
  factory RoutePointModel.fromJson(Map<String, dynamic> json) {
    return RoutePointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// В JSON (для сохранения)
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Конвертация в Domain Entity
  RoutePoint toEntity() {
    return RoutePoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
    );
  }

  /// Создание из Domain Entity
  factory RoutePointModel.fromEntity(RoutePoint entity) {
    return RoutePointModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
    );
  }
}
