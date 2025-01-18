import 'package:mix_fit/domain/entity/iot/temperature.dart';

import '../../../domain/repository/iot/temperature_repository.dart';
import '../../network/websocket/websocket_client.dart';

class TemperatureRepositoryImpl implements TemperatureRepository {
  final WebSocketClient _client;
  
  // Constructor takes an already configured WebSocketClient
  TemperatureRepositoryImpl(this._client) {
    // Only set up status listener here, no connection
    _setupStatusListener();
  }
  
  void _setupStatusListener() {
    _client.connectionStatus.listen((status) {
      switch (status) {
        case ConnectionStatus.connected:
          print('WebSocket connected');
          break;
        case ConnectionStatus.error:
          print('WebSocket error occurred');
          break;
        case ConnectionStatus.disconnected:
          print('WebSocket disconnected');
          break;
        default:
          break;
      }
    });
  }

  @override
  Future<void> controlDevice(String deviceId, bool status) {
    // TODO: implement controlDevice
    throw UnimplementedError();
  }

  @override
  Stream<Temperature> getTemperatureStream() {
    return this._client.temperatureStream.map((data) => Temperature.fromJson(data));
  }

  @override
  Stream<bool> getConnectionStatus() {
    return _client.connectionStatus.map((status) => 
      status == ConnectionStatus.connected
    );
  }
  
  // Rest of repository implementation
}