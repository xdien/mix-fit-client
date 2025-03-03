import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';

import '../repository/i_liquor_kiln_repostitory.dart';

class SetLiquorKilnOilDayMaxUsecase
    implements UseCase<void, LiquorKilnTempParams> {
  final ILiquorKilnRepository _api;
  SetLiquorKilnOilDayMaxUsecase(this._api);

  @override
  Future<void> call({required LiquorKilnTempParams params}) {
    final payload = CommandPayloadDto(
      parameters: CommandParametersDto(
        SET_DISTILLATION_DAY_TEMP_MAX: params.temperature,
      ),
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );

    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}
