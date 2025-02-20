import 'dart:async';

import 'package:core/domain/repository/websocket_repository.dart';
import 'package:core/domain/usecase/use_case.dart';


class DisconnectWebSocketUseCase extends UseCase<void, NoParams> {
  final WebSocketRepository _repository;

  DisconnectWebSocketUseCase(this._repository);

  @override
  Future<void> call({required NoParams params}) async {
    return await _repository.disconnect();
  }
}