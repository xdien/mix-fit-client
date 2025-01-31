# api_client.api.CmsApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cmsAuthControllerLogin**](CmsApi.md#cmsauthcontrollerlogin) | **POST** /cms-auth/login | 


# **cmsAuthControllerLogin**
> CmsLoginPayloadDto cmsAuthControllerLogin(cmsLoginDto)



### Example
```dart
import 'package:api_client/api.dart';

final api_instance = CmsApi();
final cmsLoginDto = CmsLoginDto(); // CmsLoginDto | 

try {
    final result = api_instance.cmsAuthControllerLogin(cmsLoginDto);
    print(result);
} catch (e) {
    print('Exception when calling CmsApi->cmsAuthControllerLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cmsLoginDto** | [**CmsLoginDto**](CmsLoginDto.md)|  | 

### Return type

[**CmsLoginPayloadDto**](CmsLoginPayloadDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

