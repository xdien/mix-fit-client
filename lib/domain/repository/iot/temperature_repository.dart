import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class ILiquorKilnRepository {
  Stream<SensorDataEventDto> getLiquorKilnKStream(String deviceId);
  Stream<bool> getDeviceStatus(String deviceId);
  Stream<DeviceStatusEventDto> getDeviceOnlineStatus(String deviceId);
  Future<void> setLiquorKilnConfigure(String deviceId, CommandPayloadDto payload);  
}