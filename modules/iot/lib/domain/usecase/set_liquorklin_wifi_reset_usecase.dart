import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';

import '../repository/i_liquor_kiln_repostitory.dart';

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