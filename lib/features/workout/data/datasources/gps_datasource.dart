import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

import '../models/route_point_model.dart';

abstract class GpsDataSource {
  Stream<RoutePointModel> getPositionStream();
}

class GpsDataSourceImpl implements GpsDataSource {
  @override
  Stream<RoutePointModel> getPositionStream() {
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Тренировка активна',
              notificationText: 'Идет запись маршрута',
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.best,
            activityType: ActivityType.fitness,
            distanceFilter: 5,
            pauseLocationUpdatesAutomatically: false,
            allowBackgroundLocationUpdates: true,
          );

    return Geolocator.getPositionStream(locationSettings: settings)
        .map((position) => RoutePointModel(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now(),
            ));
  }
}
