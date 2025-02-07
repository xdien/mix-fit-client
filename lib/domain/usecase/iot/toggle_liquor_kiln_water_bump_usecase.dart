import '../../../core/domain/usecase/use_case.dart';
import '../../../data/network/apis/lib/api.dart';
import '../../repository/iot/temperature_repository.dart';

class ToggleLiquorKilnWaterBumpUsecase implements UseCase<void, IoTParams> {
  final ILiquorKilnRepository _api;
  ToggleLiquorKilnWaterBumpUsecase(this._api);

  @override
  Future<void> call({required IoTParams params}) {
    final CommandParametersDto commandParametersDto = CommandParametersDto(
      CMD_POWER_PUMP_WATER: true,
    );
    final payload = CommandPayloadDto(
      parameters: commandParametersDto,
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}