import '../../entity/iot/temperature.dart';
import '../../repository/iot/temperature_repository.dart';

class GetTemperatureStreamUseCase {
  final TemperatureRepository _repository;

  GetTemperatureStreamUseCase(this._repository);

  Stream<Temperature> execute() {
    return _repository.getTemperatureStream();
  }
}