import 'dart:async';

import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/data/network/websocket/websocket_service.dart';

import '../../../domain/repository/iot/temperature_repository.dart';

class TemperatureRepositoryImpl implements ITemperatureRepository {
  final SocketService _service;
  final _temperatureController =
      StreamController<OilTemperatureData>.broadcast();

  TemperatureRepositoryImpl(this._service) {
    _service.on('sensor.temperature', _handleTemperatureEvent);
  }

  void _handleTemperatureEvent(dynamic event) {
    final data = OilTemperatureData.fromJson(event);
    if (data == null) return;
    _temperatureController.add(data);
  }

  @override
  Stream<OilTemperatureData> getTemperatureStream() {
    return _temperatureController.stream;
  }

  @override
  Stream<bool> getDeviceStatus(String deviceId) {
    throw UnimplementedError();
  }
}
