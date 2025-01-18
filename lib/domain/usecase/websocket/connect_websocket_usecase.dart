
import 'dart:async';

import '../../../core/domain/usecase/use_case.dart';
import '../../repository/websocket/websocket_repository.dart';

class ConnectWebSocketUseCase implements UseCase<void, NoParams> {
  final WebSocketRepository _repository;

  ConnectWebSocketUseCase(this._repository);

  @override
  FutureOr<void> call({required NoParams params}) async {
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