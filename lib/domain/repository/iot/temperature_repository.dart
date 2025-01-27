import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class ILiquorKilnRepository {
  Stream<SensorDataEventDto> getLiquorKilnKStream();
  Stream<bool> getDeviceStatus(String deviceId);
  Stream<DeviceStatusEventDto> getDeviceOnlineStatus(String deviceId);
  Future<void> setHeating(String deviceId, CommandPayloadDto payload);  
}