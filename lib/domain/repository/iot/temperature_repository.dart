import '../../entity/iot/temperature.dart';

abstract class TemperatureRepository {
  Stream<Temperature> getTemperatureStream();
  Stream<bool> getConnectionStatus();
  // Future<void> controlDevice(String deviceId, bool status);
}