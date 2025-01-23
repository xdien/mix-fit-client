import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class ILiquorKilnRepository {
  Stream<SensorDataEventDto> getLiquorKilnKStream();
  Stream<bool> getDeviceStatus(String deviceId);
}