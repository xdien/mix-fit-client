import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';
import 'package:mix_fit/domain/repository/iot/temperature_repository.dart';

class SetLiquorKilnOverHeatUsecase implements UseCase<void, LiquorKilnTempParams> {
  final ILiquorKilnRepository _api;
  SetLiquorKilnOverHeatUsecase(this._api);

  @override
  Future<void> call({required LiquorKilnTempParams params}) {
    final CommandParametersDto commandParametersDto = CommandParametersDto(
      SET_OVERHEAT_TEMP: params.temperature,
    );
    final payload = CommandPayloadDto(
      parameters: commandParametersDto,
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}