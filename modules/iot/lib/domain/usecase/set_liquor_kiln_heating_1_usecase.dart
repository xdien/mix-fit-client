import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';

import '../../constants/heating_params.dart';
import '../repository/i_liquor_kiln_repostitory.dart';

class SetLiquorKilnHeating1Usecase implements UseCase<void, HeatingParams> {
  final ILiquorKilnRepository _api;
  SetLiquorKilnHeating1Usecase(this._api);

  @override
  Future<void> call({required HeatingParams params}) {
    final payload = CommandPayloadDto(
      parameters: CommandParametersDto(
        cMDHEATER1: params.isOn,
      ),
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}