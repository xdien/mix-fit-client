import 'package:api_client/api.dart';

abstract class ILiquorKilnRepository {
  Stream<SensorDataEventDto> getLiquorKilnKStream(String deviceId);
  Stream<bool> getDeviceStatus(String deviceId);
  Stream<DeviceStatusEventDto> getDeviceOnlineStatus(String deviceId);
  Future<void> setLiquorKilnConfigure(String deviceId, CommandPayloadDto payload);  
}