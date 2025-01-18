import '../../repository/iot/temperature_repository.dart';

class GetConnectionStatusUseCase {
  final TemperatureRepository _repository;

  GetConnectionStatusUseCase(this._repository);

  Stream<bool> execute() {
    return _repository.getConnectionStatus();
  }
}