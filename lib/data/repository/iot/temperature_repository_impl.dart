import 'package:mix_fit/data/network/websocket/websocket_service.dart';
import 'package:mix_fit/domain/entity/iot/temperature.dart';

import '../../../domain/repository/iot/temperature_repository.dart';

class TemperatureRepositoryImpl implements TemperatureRepository {
  final WebSocketService _client;
  
  TemperatureRepositoryImpl(this._client) {
    // Only set up status listener here, no connection
  }
  
  @override
  Stream<Temperature> getTemperatureStream() {
    throw UnimplementedError();
  }

  @override
  Stream<bool> getConnectionStatus() {
    throw UnimplementedError();

  }
  
  // Rest of repository implementation
}