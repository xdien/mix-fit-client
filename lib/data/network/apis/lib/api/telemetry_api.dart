//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class TelemetryApi {
  TelemetryApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get latest metrics for device
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///
  /// * [String] metrics (required):
  Future<Response> deviceTelemetryControllerGetLatestMetricsWithHttpInfo(String deviceId, String metrics,) async {
    // ignore: prefer_const_declarations
    final path = r'/telemetry/{deviceId}/latest'
      .replaceAll('{deviceId}', deviceId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'metrics', metrics));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get latest metrics for device
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///
  /// * [String] metrics (required):
  Future<void> deviceTelemetryControllerGetLatestMetrics(String deviceId, String metrics,) async {
    final response = await deviceTelemetryControllerGetLatestMetricsWithHttpInfo(deviceId, metrics,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get metric history for device
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///
  /// * [String] metricName (required):
  ///
  /// * [String] startTime (required):
  ///
  /// * [String] endTime (required):
  ///
  /// * [num] aggregateMinutes (required):
  Future<Response> deviceTelemetryControllerGetMetricHistoryWithHttpInfo(String deviceId, String metricName, String startTime, String endTime, num aggregateMinutes,) async {
    // ignore: prefer_const_declarations
    final path = r'/telemetry/{deviceId}/history/{metricName}'
      .replaceAll('{deviceId}', deviceId)
      .replaceAll('{metricName}', metricName);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'startTime', startTime));
      queryParams.addAll(_queryParams('', 'endTime', endTime));
      queryParams.addAll(_queryParams('', 'aggregateMinutes', aggregateMinutes));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get metric history for device
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///
  /// * [String] metricName (required):
  ///
  /// * [String] startTime (required):
  ///
  /// * [String] endTime (required):
  ///
  /// * [num] aggregateMinutes (required):
  Future<void> deviceTelemetryControllerGetMetricHistory(String deviceId, String metricName, String startTime, String endTime, num aggregateMinutes,) async {
    final response = await deviceTelemetryControllerGetMetricHistoryWithHttpInfo(deviceId, metricName, startTime, endTime, aggregateMinutes,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Save device telemetry data
  ///
  /// Saves a batch of telemetry data for a specific device including multiple metrics
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TelemetryPayloadDto] telemetryPayloadDto (required):
  Future<Response> deviceTelemetryControllerSaveTelemetryWithHttpInfo(TelemetryPayloadDto telemetryPayloadDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/telemetry';

    // ignore: prefer_final_locals
    Object? postBody = telemetryPayloadDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Save device telemetry data
  ///
  /// Saves a batch of telemetry data for a specific device including multiple metrics
  ///
  /// Parameters:
  ///
  /// * [TelemetryPayloadDto] telemetryPayloadDto (required):
  Future<void> deviceTelemetryControllerSaveTelemetry(TelemetryPayloadDto telemetryPayloadDto,) async {
    final response = await deviceTelemetryControllerSaveTelemetryWithHttpInfo(telemetryPayloadDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
