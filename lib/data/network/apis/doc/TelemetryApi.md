# api_client.api.TelemetryApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deviceTelemetryControllerGetLatestMetrics**](TelemetryApi.md#devicetelemetrycontrollergetlatestmetrics) | **GET** /telemetry/{deviceId}/latest | Get latest metrics for device
[**deviceTelemetryControllerGetMetricHistory**](TelemetryApi.md#devicetelemetrycontrollergetmetrichistory) | **GET** /telemetry/{deviceId}/history/{metricName} | Get metric history for device
[**deviceTelemetryControllerSaveTelemetry**](TelemetryApi.md#devicetelemetrycontrollersavetelemetry) | **POST** /telemetry | Save device telemetry data


# **deviceTelemetryControllerGetLatestMetrics**
> deviceTelemetryControllerGetLatestMetrics(deviceId, metrics)

Get latest metrics for device

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TelemetryApi();
final deviceId = deviceId_example; // String | 
final metrics = metrics_example; // String | 

try {
    api_instance.deviceTelemetryControllerGetLatestMetrics(deviceId, metrics);
} catch (e) {
    print('Exception when calling TelemetryApi->deviceTelemetryControllerGetLatestMetrics: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **String**|  | 
 **metrics** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deviceTelemetryControllerGetMetricHistory**
> deviceTelemetryControllerGetMetricHistory(deviceId, metricName, startTime, endTime, aggregateMinutes)

Get metric history for device

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TelemetryApi();
final deviceId = deviceId_example; // String | 
final metricName = metricName_example; // String | 
final startTime = startTime_example; // String | 
final endTime = endTime_example; // String | 
final aggregateMinutes = 8.14; // num | 

try {
    api_instance.deviceTelemetryControllerGetMetricHistory(deviceId, metricName, startTime, endTime, aggregateMinutes);
} catch (e) {
    print('Exception when calling TelemetryApi->deviceTelemetryControllerGetMetricHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **String**|  | 
 **metricName** | **String**|  | 
 **startTime** | **String**|  | 
 **endTime** | **String**|  | 
 **aggregateMinutes** | **num**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deviceTelemetryControllerSaveTelemetry**
> deviceTelemetryControllerSaveTelemetry(telemetryPayloadDto)

Save device telemetry data

Saves a batch of telemetry data for a specific device including multiple metrics

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TelemetryApi();
final telemetryPayloadDto = TelemetryPayloadDto(); // TelemetryPayloadDto | 

try {
    api_instance.deviceTelemetryControllerSaveTelemetry(telemetryPayloadDto);
} catch (e) {
    print('Exception when calling TelemetryApi->deviceTelemetryControllerSaveTelemetry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **telemetryPayloadDto** | [**TelemetryPayloadDto**](TelemetryPayloadDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

