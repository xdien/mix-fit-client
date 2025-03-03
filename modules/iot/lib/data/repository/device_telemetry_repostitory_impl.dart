import 'dart:async';
import 'package:api_client/api.dart';
import 'package:iot/domain/repository/i_device_telemetry_repostitory.dart';

class DeviceHistoryRepostitoryImpl implements IDeviceTelemetryRepostitory {

  final ApiClient _apiClient;
  late final TelemetryApi _telemetryApi;

  DeviceHistoryRepostitoryImpl(this._apiClient) {
    _telemetryApi = TelemetryApi(_apiClient);
  }

  @override
  Future<List<TelemetryAggregateResponseDto>?> getTelemetryData(String deviceId,String metricName, DateTime from, DateTime to, int aggregateSeconds) {
    return _telemetryApi.deviceTelemetryControllerGetMetricHistory(deviceId, metricName, from, to, aggregateSeconds: aggregateSeconds);
  }
}
