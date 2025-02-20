import 'dart:async';
import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';

import '../../repository/iot/temperature_repository.dart';

class GetLiquorKilnOnlineStreamUseCase implements UseCase<Stream<DeviceStatusEventDto>, String> {
  final ILiquorKilnRepository _repository;

  GetLiquorKilnOnlineStreamUseCase(this._repository);

  @override
  Stream<DeviceStatusEventDto> call({required String params}) {
    return _repository.getDeviceOnlineStatus(params);
  }
}