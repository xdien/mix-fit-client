// lib/presentation/liquor_kiln/store/liquor_kiln_store.dart
import 'package:flutter/material.dart';
import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/domain/usecase/iot/set_liquor_kiln_oil_day_min_usecase.dart';
import 'package:mobx/mobx.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/domain/usecase/use_case.dart';
import '../../../domain/usecase/iot/get_liquorklin_online_steam_usecase.dart';
import '../../../domain/usecase/iot/get_temperature_stream_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_heating_1_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_oil_day_max_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_overheat_usecase.dart';
import '../../../domain/usecase/iot/update_time_liquor_kiln_usecase.dart';
import '../../../domain/usecase/websocket/get_connection_status_usecase.dart';
// ... other imports

part 'liquor_kiln_store.g.dart';

class LiquorKilnStore = _LiquorKilnStore with _$LiquorKilnStore;

abstract class _LiquorKilnStore with Store {
  final String deviceId;
  final GetConnectionStatusUseCase _getConnectionStatusUseCase;
  final GetLiquorKilnStreamUseCase _getLiquorKilnStreamUseCase;
  final GetLiquorKilnOnlineStreamUseCase _getLiquorKilnOnlineStreamUseCase;
  final SetLiquorKilnHeating1Usecase _setLiquorKilnHeating1Usecase;

  // test manual 
  final SetLiquorKilnOverHeatUsecase _setLiquorKilnOverHeatUsecase;
  final SetLiquorKilnOilDayMinUsecase _setLiquorKilnOilDayMinUsecase;
  final SetLiquorKilnOilDayMaxUsecase _setLiquorKilnOilDayMaxUsecase;
  final UpdateTimeLiquorKilnUsecase _updateTimeLiquorKilnUsecase;

  _LiquorKilnStore(
    this._getConnectionStatusUseCase,
    this._getLiquorKilnStreamUseCase,
    this._getLiquorKilnOnlineStreamUseCase,
    this._setLiquorKilnHeating1Usecase,
    this._setLiquorKilnOverHeatUsecase,
    this._setLiquorKilnOilDayMinUsecase,
    this._setLiquorKilnOilDayMaxUsecase,
    this._updateTimeLiquorKilnUsecase,
    this.deviceId,
  ) {
    _setupSubscriptions(this.deviceId);
  }

  // Observables
  @observable
  ObservableList<FlSpot> temperatureData = ObservableList<FlSpot>();

  @observable
  bool isSocketConnected = false;

  @observable
  bool isOnline = false;

  @observable
  double currentTemperature = 0.0;

  @observable
  bool isControl1On = false;

  @observable
  bool isControl2On = false;

  @observable
  bool isControl3On = false;

  // Computed values
  @computed
  Color get temperatureColor {
    if (currentTemperature > 80) return Colors.red;
    if (currentTemperature > 50) return Colors.orange;
    return Colors.green;
  }

  // Actions
  @action
  Future<void> toggleControl(String controlType, bool currentState) async {
    try {
      await _setLiquorKilnHeating1Usecase.call(
        params: HeatingParams(
          deviceId: this.deviceId,
          isOn: !currentState,
        ),
      );

      runInAction(() {
        switch (controlType) {
          case 'control1':
            isControl1On = !currentState;
            break;
          case 'control2':
            isControl2On = !currentState;
            break;
          case 'control3':
            isControl3On = !currentState;
            break;
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle control: $e');
    }
  }

  // Private methods
  void _setupSubscriptions(String forDeviceId) {
    // final params = LiquorKilnTempParams(
    //   deviceId: 'esp8266_001',
    //   temperature: 145,
    // );
    // _setLiquorKilnOverHeatUsecase.call(params: params);
    // final minParams = LiquorKilnTempParams(
    //   deviceId: 'esp8266_001',
    //   temperature: 129,
    // );
    // _setLiquorKilnOilDayMinUsecase.call(params: minParams);
    // final maxParams = LiquorKilnTempParams(
    //   deviceId: 'esp8266_001',
    //   temperature: 131,
    // );
    // _setLiquorKilnOilDayMaxUsecase.call(params: maxParams);
    //  final timeParams = UpdateTimeLiquorKilnPrams(
    //     deviceId: 'esp8266_001'
    //   );
    // _updateTimeLiquorKilnUsecase.call(params: timeParams);
    _getLiquorKilnStreamUseCase.call(params: IoTParams(deviceId: forDeviceId)).listen(
      (data) {
        runInAction(() {
          var metrics = data.telemetryData.metrics;
          for (var metric in metrics) {
            if (metric.name == 'oil_temperature') {
              currentTemperature = (metric.value as num).toDouble();
              final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
              
              // Debug log
              print('Current Temperature: $currentTemperature°C at timestamp: $timestamp');
              print('Current data points: ${temperatureData.length}');
              
              // Thêm điểm mới vào danh sách
              temperatureData.add(FlSpot(timestamp, currentTemperature));
              
              // Giữ lại 60 điểm gần nhất
              if (temperatureData.length > 60) {
                temperatureData.removeRange(0, temperatureData.length - 60);
              }
              
              break;
            }
          }
        });
      },
    );

    _getConnectionStatusUseCase.call(params: NoParams()).listen(
      (connected) {
        runInAction(() {
          isSocketConnected = connected;
        });
      },
    );

    _getLiquorKilnOnlineStreamUseCase.call(params: 'esp8266_001').listen(
      (deviceStatus) {
        runInAction(() {
          isOnline = deviceStatus.status == DeviceStatusEventDtoStatusEnum.ONLINE;
        });
      },
    );
  }

  void dispose() {
    // Clean up subscriptions if needed
  }
}