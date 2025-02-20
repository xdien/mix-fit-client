import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';
import 'package:mix_fit/domain/repository/iot/temperature_repository.dart';


class HeatingParams implements IIotParam {
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
      parameters: CommandParametersDto(
        cMDHEATER1: params.isOn,
      ),
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}