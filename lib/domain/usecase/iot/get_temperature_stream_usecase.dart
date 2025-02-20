import 'dart:async';
import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';
import '../../repository/iot/temperature_repository.dart';

class GetLiquorKilnStreamUseCase implements UseCase<Stream<SensorDataEventDto>, IoTParams> {
  final ILiquorKilnRepository _repository;

  GetLiquorKilnStreamUseCase(this._repository);

  @override
  Stream<SensorDataEventDto> call({required IoTParams params}) {
    return _repository.getLiquorKilnKStream(params.deviceId);
  }
}