
import 'dart:async';

import '../../../core/domain/usecase/use_case.dart';
import '../../repository/websocket/websocket_repository.dart';


class ConnectWebSocketUseCase implements UseCase<void, NoParams> {
  final WebSocketRepository _repository;
  final int maxRetries;
  final Duration initialDelay;

  ConnectWebSocketUseCase(
    this._repository, {
    this.maxRetries = 5,
    this.initialDelay = const Duration(seconds: 1),
  });
  
  @override
  FutureOr<void> call({required NoParams params}) async{
    int retryCount = 0;
    Duration delay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        await _repository.connect();
        return;
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) rethrow;
        
        // Exponential backoff
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }
}