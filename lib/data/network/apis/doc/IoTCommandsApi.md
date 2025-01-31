# api_client.api.IoTCommandsApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**ioTCommandControllerGetStatus**](IoTCommandsApi.md#iotcommandcontrollergetstatus) | **GET** /iot/commands/{commandId}/status | Get status of command
[**ioTCommandControllerSendCommand**](IoTCommandsApi.md#iotcommandcontrollersendcommand) | **POST** /iot/commands/{deviceId} | Send command to device
[**ioTCommandV1ControllerSendCommand**](IoTCommandsApi.md#iotcommandv1controllersendcommand) | **POST** /v1/iot/commands/{deviceId} | Send command to device


# **ioTCommandControllerGetStatus**
> CommandStatusDto ioTCommandControllerGetStatus(commandId)

Get status of command

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = IoTCommandsApi();
final commandId = cmd-123; // String | ID of the command

try {
    final result = api_instance.ioTCommandControllerGetStatus(commandId);
    print(result);
} catch (e) {
    print('Exception when calling IoTCommandsApi->ioTCommandControllerGetStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commandId** | **String**| ID of the command | 

### Return type

[**CommandStatusDto**](CommandStatusDto.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ioTCommandControllerSendCommand**
> CommandStatusDto ioTCommandControllerSendCommand(deviceId, commandPayloadDto)

Send command to device

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = IoTCommandsApi();
final deviceId = device-123; // String | ID of the device
final commandPayloadDto = CommandPayloadDto(); // CommandPayloadDto | 

try {
    final result = api_instance.ioTCommandControllerSendCommand(deviceId, commandPayloadDto);
    print(result);
} catch (e) {
    print('Exception when calling IoTCommandsApi->ioTCommandControllerSendCommand: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **String**| ID of the device | 
 **commandPayloadDto** | [**CommandPayloadDto**](CommandPayloadDto.md)|  | 

### Return type

[**CommandStatusDto**](CommandStatusDto.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ioTCommandV1ControllerSendCommand**
> CommandStatusDto ioTCommandV1ControllerSendCommand(deviceId, commandPayloadDto)

Send command to device

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = IoTCommandsApi();
final deviceId = device-123; // String | ID of the device
final commandPayloadDto = CommandPayloadDto(); // CommandPayloadDto | 

try {
    final result = api_instance.ioTCommandV1ControllerSendCommand(deviceId, commandPayloadDto);
    print(result);
} catch (e) {
    print('Exception when calling IoTCommandsApi->ioTCommandV1ControllerSendCommand: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **String**| ID of the device | 
 **commandPayloadDto** | [**CommandPayloadDto**](CommandPayloadDto.md)|  | 

### Return type

[**CommandStatusDto**](CommandStatusDto.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

