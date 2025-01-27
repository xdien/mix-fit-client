
import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/domain/repository/iot/temperature_repository.dart';

import '../../../core/domain/usecase/use_case.dart';

class SetLiquorKilnOverHeatUsecase implements UseCase<void, LiquorKilnTempParams> {
  final ILiquorKilnRepository _api;
  SetLiquorKilnOverHeatUsecase(this._api);

  @override
  Future<void> call({required LiquorKilnTempParams params}) {
    final payload = CommandPayloadDto(
      parameters: {
        LiquorKilnCommandActionDtoActionEnum.SET_OVERHEAT_TEMP.value: params as dynamic,
      }, 
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}