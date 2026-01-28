import 'dart:async';

import '../models/route_point_model.dart';

abstract class GpsDataSource {
  Stream<RoutePointModel> getPositionStream();
}

class GpsDataSourceImpl implements GpsDataSource {
  @override
  Stream<RoutePointModel> getPositionStream() {
    // Заглушка: пока GPS не подключен
    return const Stream.empty();
  }
}
