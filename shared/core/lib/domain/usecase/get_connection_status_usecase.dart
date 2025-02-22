import 'package:core/domain/repository/websocket_repository.dart';
import 'package:core/domain/usecase/use_case.dart';

class GetConnectionStatusUseCase extends UseCase<Stream<bool>, NoParams> {
  final WebSocketRepository _repository;

  GetConnectionStatusUseCase(this._repository);

  @override
  Stream<bool> call({required NoParams params}) {
    return _repository.getConnectionStatus();
  }
}
