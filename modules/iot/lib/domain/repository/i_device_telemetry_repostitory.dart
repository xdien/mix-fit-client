import 'package:api_client/api.dart';

abstract class IDeviceTelemetryRepostitory {
    // get history data
  Future<List<TelemetryAggregateResponseDto>?> getTelemetryData(String deviceId,String metricName, DateTime from, DateTime to, int aggregateSeconds) ;
}