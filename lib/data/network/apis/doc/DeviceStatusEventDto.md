# api_client.model.DeviceStatusEventDto

## Load the model package
```dart
import 'package:api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**eventType** | [**IoTEvents**](IoTEvents.md) |  | 
**deviceId** | **String** | Unique identifier of the device | 
**status** | **String** | Device status | 
**lastHeartbeat** | **String** | Last heartbeat timestamp | 
**batteryLevel** | **num** | Battery level percentage | [optional] 
**firmwareVersion** | **String** | Firmware version | [optional] 
**ipAddress** | **String** | Device IP address | [optional] 
**signalStrength** | **num** | Signal strength in dBm | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


