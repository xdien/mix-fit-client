import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class ITemperatureRepository {
  Stream<OilTemperatureData> getTemperatureStream();
  Stream<bool> getConnectionStatus();
  // Future<void> controlDevice(String deviceId, bool status);
}