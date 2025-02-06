import '../../../core/domain/usecase/use_case.dart';
import '../../../data/network/apis/lib/api.dart';
import '../../repository/iot/temperature_repository.dart';

class SetLiquorklinWifiResetUsecase implements UseCase<void, IoTParams> {
  final ILiquorKilnRepository _api;
  SetLiquorklinWifiResetUsecase(this._api);

  @override
  Future<void> call({required IoTParams params}) {
    final CommandParametersDto commandParametersDto = CommandParametersDto(
      RESET_WIFI: true,
    );
    final payload = CommandPayloadDto(
      parameters: commandParametersDto,
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}