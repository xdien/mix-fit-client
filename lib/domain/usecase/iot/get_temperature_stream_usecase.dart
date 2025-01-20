import 'package:mix_fit/data/network/apis/lib/api.dart';
import '../../repository/iot/temperature_repository.dart';

class GetTemperatureStreamUseCase {
  final ITemperatureRepository _repository;

  GetTemperatureStreamUseCase(this._repository);

  Stream<OilTemperatureData> execute() {
    return _repository.getTemperatureStream();
  }
}