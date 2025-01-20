import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class ITemperatureRepository {
  Stream<OilTemperatureData> getTemperatureStream();
  Stream<bool> getDeviceStatus(String deviceId);
}