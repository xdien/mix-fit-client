import 'dart:async';

import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/data/network/websocket/websocket_service.dart';

import '../../../domain/repository/iot/temperature_repository.dart';

class TemperatureRepositoryImpl implements ILiquorKilnRepository {
  final SocketService _service;
  final _temperatureController =
      StreamController<SensorDataEventDto>.broadcast();
  final _onlineStatus =
      StreamController<DeviceStatusEventDto>.broadcast();

  TemperatureRepositoryImpl(this._service) {
    _service.on(IoTEvents.sensorDataMonitoring.value+"/dev001", _handleTemperatureEvent);
    _service.on(IoTEvents.controlStatus.value+"/dev001", _handleOnlineStatusEvent);
  }

  void _handleTemperatureEvent(dynamic event) {
    final data = SensorDataEventDto.fromJson(event);
    if (data == null) return;
    _temperatureController.add(data);
  }

  void _handleOnlineStatusEvent(dynamic event) {
    final data = DeviceStatusEventDto.fromJson(event);
    if (data == null) return;
    _onlineStatus.add(data);
  }

  @override
  Stream<bool> getDeviceStatus(String deviceId) {
    throw UnimplementedError();
  }
  
  @override
  Stream<SensorDataEventDto> getLiquorKilnKStream() {
    return _temperatureController.stream;
  }
  
  @override
  Stream<DeviceStatusEventDto> getDeviceOnlineStatus(String deviceId) {
    return _onlineStatus.stream;
  }
}
