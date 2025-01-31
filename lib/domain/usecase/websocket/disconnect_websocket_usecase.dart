import 'dart:async';
import '../../../core/domain/usecase/use_case.dart';
import '../../repository/websocket/websocket_repository.dart';


class DisconnectWebSocketUseCase extends UseCase<void, NoParams> {
  final WebSocketRepository _repository;

  DisconnectWebSocketUseCase(this._repository);

  @override
  Future<void> call({required NoParams params}) async {
    return await _repository.disconnect();
  }
}