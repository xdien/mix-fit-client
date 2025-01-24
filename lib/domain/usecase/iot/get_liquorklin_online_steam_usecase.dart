import 'dart:async';

import 'package:mix_fit/data/network/apis/lib/api.dart';

import '../../../core/domain/usecase/use_case.dart';
import '../../repository/iot/temperature_repository.dart';

class GetLiquorKilnOnlineStreamUseCase implements UseCase<Stream<DeviceStatusEventDto>, String> {
  final ILiquorKilnRepository _repository;

  GetLiquorKilnOnlineStreamUseCase(this._repository);

  @override
  Stream<DeviceStatusEventDto> call({required String params}) {
    return _repository.getDeviceOnlineStatus(params);
  }
}