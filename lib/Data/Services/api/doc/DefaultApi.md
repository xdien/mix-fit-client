# api_client.api.DefaultApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**test11Get**](DefaultApi.md#test11get) | **GET** /test11 | 


# **test11Get**
> Test11Get200Response test11Get()



### Example
```dart
import 'package:api_client/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.test11Get();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->test11Get: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Test11Get200Response**](Test11Get200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

