import 'package:mobx/mobx.dart';

import '../../../core/domain/usecase/use_case.dart';
import '../../../domain/usecase/iot/set_liquorklin_wifi_reset_usecase.dart';
part 'liquor_kiln_control_store.g.dart';

class LiquorKilnControlStore = _LiquorKilnControlStore with _$LiquorKilnControlStore;

abstract class _LiquorKilnControlStore with Store {
  final SetLiquorklinWifiResetUsecase _wifiResetUsecase;
  final String _deviceId;
  
  
  _LiquorKilnControlStore(
    this._wifiResetUsecase,
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

  @action
  Future<void> resetWifi() async {
    await _wifiResetUsecase.call(
      params: IoTParams(deviceId: this._deviceId),
    );
  }

  // Add other actions...
}