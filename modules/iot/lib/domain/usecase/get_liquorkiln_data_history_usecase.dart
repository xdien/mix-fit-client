import 'dart:async';
import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';

import '../repository/i_liquor_kiln_repostitory.dart';

class GetLiquorKilnOnlineStreamUseCase implements UseCase<Stream<DeviceStatusEventDto>, String> {
  final ILiquorKilnRepository _repository;

  GetLiquorKilnOnlineStreamUseCase(this._repository);

  @override
  Stream<DeviceStatusEventDto> call({required String params}) {
    return _repository.getDeviceOnlineStatus(params);
  }
}