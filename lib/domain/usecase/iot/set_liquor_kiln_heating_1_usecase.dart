
import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/domain/repository/iot/temperature_repository.dart';

import '../../../core/domain/usecase/use_case.dart';

class HeatingParams {
  final String deviceId;
  final bool isOn;

  HeatingParams({
    required this.deviceId,
    required this.isOn,
  });
}

class SetLiquorKilnHeating1Usecase implements UseCase<void, HeatingParams> {
  final ILiquorKilnRepository _api;
  SetLiquorKilnHeating1Usecase(this._api);

  @override
  Future<void> call({required HeatingParams params}) {
    final payload = CommandPayloadDto(
      parameters: {
        LiquorKilnCommandActionDtoActionEnum.cMDHEATER1.value: params,
      }, 
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setHeating(params.deviceId, payload);
  }
}