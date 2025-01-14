import 'package:injectable/injectable.dart';
import '../../repository/websocket/websocket_repository.dart';

// Base UseCase interface
abstract class UseCase<Type, Params> {
  Future<Type> execute(Params params);
}

// No params class for use cases that don't need parameters
class NoParams {}

@injectable
class ConnectWebSocketUseCase implements UseCase<void, NoParams> {
  final WebSocketRepository _repository;

  ConnectWebSocketUseCase(this._repository);

  @override
  Future<void> execute(NoParams params) async {
    try {
      await _repository.connect();
    } catch (e) {
      throw WebSocketConnectionException('Failed to connect: ${e.toString()}');
    }
  }
}

class WebSocketConnectionException implements Exception {
  final String message;
  WebSocketConnectionException(this.message);

  @override
  String toString() => message;
}