import 'package:core/domain/usecase/use_case.dart';
import 'package:mix_fit/domain/usecase/iot/toggle_liquor_kiln_water_bump_usecase.dart';
import 'package:mobx/mobx.dart';

import '../../../domain/usecase/iot/set_liquorklin_wifi_reset_usecase.dart';
import '../../../domain/usecase/iot/update_time_liquor_kiln_usecase.dart';
part 'liquor_kiln_control_store.g.dart';

class LiquorKilnControlStore = _LiquorKilnControlStore with _$LiquorKilnControlStore;

abstract class _LiquorKilnControlStore with Store {
  final SetLiquorklinWifiResetUsecase _wifiResetUsecase;
  final UpdateTimeLiquorKilnUsecase _updateTimeUsecase;
  final ToggleLiquorKilnWaterBumpUsecase _toggleWaterPumpUsecase;
  final String _deviceId;
  
  
  _LiquorKilnControlStore(
    this._wifiResetUsecase,
    this._updateTimeUsecase,
    this._toggleWaterPumpUsecase,
    this._deviceId,
  ) {
    // _setupSubscriptions(this._deviceId);
  }
  

  @observable
  bool isSocketConnected = false;

  @observable
  bool isHeater1On = false;

  @observable
  bool isHeater2On = false;

  @observable
  bool isHeater3On = false;

  @observable
  double overHeatTemp = 0.0;

  @observable
  double coolingTemp = 0.0;
  @observable
  bool isWaterPumpOn = false;

  @action
  Future<void> resetWifi() async {
    await _wifiResetUsecase.call(
      params: IoTParams(deviceId: this._deviceId),
    );
  }

  @action
  Future<void> updateSystemTime() async {
    await _updateTimeUsecase.call(
      params: UpdateTimeLiquorKilnPrams(deviceId: this._deviceId),
    );
  }

  @action
  Future<void> toggleWaterPump() async {
    await _toggleWaterPumpUsecase.call(
      params: IoTParams(deviceId: this._deviceId),
    );
  }
}