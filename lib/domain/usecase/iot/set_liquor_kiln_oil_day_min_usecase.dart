
import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/domain/repository/iot/temperature_repository.dart';

import '../../../core/domain/usecase/use_case.dart';

class SetLiquorKilnOilDayMinUsecase implements UseCase<void, LiquorKilnTempParams> {
  final ILiquorKilnRepository _api;
  SetLiquorKilnOilDayMinUsecase(this._api);

  @override
  Future<void> call({required LiquorKilnTempParams params}) {
    final payload = CommandPayloadDto(
      parameters: CommandParametersDto(
        SET_DISTILLATION_DAY_TEMP_MIN: params.temperature,
      ), 
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}