// lib/presentation/liquor_kiln/store/liquor_kiln_store.dart

import 'package:flutter/material.dart';
import 'package:mix_fit/domain/usecase/iot/set_liquor_kiln_heating_1_usecase.dart';
import 'package:mobx/mobx.dart';
import 'package:mix_fit/domain/usecase/iot/get_liquorklin_online_steam_usecase.dart';
import 'package:mix_fit/domain/usecase/iot/get_temperature_stream_usecase.dart';
import 'package:mix_fit/domain/usecase/websocket/get_connection_status_usecase.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/domain/usecase/use_case.dart';
import '../../../data/network/apis/lib/api.dart';

part 'liquor_kiln_store.g.dart';

class LiquorKilnStore = _LiquorKilnStore with _$LiquorKilnStore;

abstract class _LiquorKilnStore with Store {
  final GetConnectionStatusUseCase _getConnectionStatusUseCase;
  final GetLiquorKilnStreamUseCase _getLiquorKilnStreamUseCase;
  final GetLiquorKilnOnlineStreamUseCase _getLiquorKilnOnlineStreamUseCase;
  final SetLiquorKilnHeating1Usecase _setLiquorKilnHeating1Usecase;

  _LiquorKilnStore(
    this._getConnectionStatusUseCase,
    this._getLiquorKilnStreamUseCase,
    this._getLiquorKilnOnlineStreamUseCase,
    this._setLiquorKilnHeating1Usecase,
  ) {
    _setupSubscriptions();
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
      await _setLiquorKilnHeating1Usecase.call(params: HeatingParams(
        deviceId: 'device_id',
        isOn: !currentState,
      ));

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
    } catch (e) {
      throw Exception('Failed to toggle control: $e');
    }
  }

  // Private methods
  void _setupSubscriptions() async {
    _getLiquorKilnStreamUseCase.call(params: NoParams()).listen(
      (data) {
        var metrics = data.telemetryData.metrics;
        for (var metric in metrics) {
          if (metric.name == 'oli_temperature') {
            currentTemperature = (metric.value as num).toDouble();
            final timestamp = data.telemetryData.timestamp.millisecondsSinceEpoch.toDouble();
            temperatureData.add(FlSpot(timestamp, currentTemperature));
            break;
          }
        }
        if (temperatureData.length > 60) {
          temperatureData.removeAt(0);
        }
      },
    );

    _getConnectionStatusUseCase.call(params: NoParams()).listen(
      (connected) {
        isSocketConnected = connected;
      },
    );

    _getLiquorKilnOnlineStreamUseCase.call(params: 'device_id').listen(
      (deviceStatus) {
        isOnline = deviceStatus.status == DeviceStatusEventDtoStatusEnum.ONLINE;
      },
    );
  }

  void dispose() {
    // Clean up subscriptions
  }
}
