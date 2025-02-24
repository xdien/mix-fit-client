import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';
import '../../constants/update_time_liquor_kiln_prams.dart';
import '../repository/i_liquor_kiln_repostitory.dart';

class UpdateTimeLiquorKilnUsecase implements UseCase<void, UpdateTimeLiquorKilnPrams> {
  final ILiquorKilnRepository _api;
  UpdateTimeLiquorKilnUsecase(this._api);

  @override
  Future<void> call({required UpdateTimeLiquorKilnPrams params}) {
    final CommandParametersDto commandParametersDto = CommandParametersDto(
      UPDATE_TIME_NTP: true,
    );
    final payload = CommandPayloadDto(
      parameters: commandParametersDto,
      deviceType: DeviceTypeDtoTypeEnum.LIQUOR_KILN.value,
    );
    
    return _api.setLiquorKilnConfigure(params.deviceId, payload);
  }
}