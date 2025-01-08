# api_client.api.UsersApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**userControllerAdmin**](UsersApi.md#usercontrolleradmin) | **GET** /users/admin | 
[**userControllerGetUser**](UsersApi.md#usercontrollergetuser) | **GET** /users/{id} | 
[**userControllerGetUsers**](UsersApi.md#usercontrollergetusers) | **GET** /users | Get users list


# **userControllerAdmin**
> userControllerAdmin()



### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UsersApi();

try {
    api_instance.userControllerAdmin();
} catch (e) {
    print('Exception when calling UsersApi->userControllerAdmin: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userControllerGetUser**
> UserDto userControllerGetUser(id)



### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UsersApi();
final id = id_example; // String | 

try {
    final result = api_instance.userControllerGetUser(id);
    print(result);
} catch (e) {
    print('Exception when calling UsersApi->userControllerGetUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**UserDto**](UserDto.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userControllerGetUsers**
> Object userControllerGetUsers(order, page, take, q)

Get users list

### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UsersApi();
final order = ; // Order | 
final page = 56; // int | Page number
final take = 56; // int | Items per page
final q = q_example; // String | 

try {
    final result = api_instance.userControllerGetUsers(order, page, take, q);
    print(result);
} catch (e) {
    print('Exception when calling UsersApi->userControllerGetUsers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **order** | [**Order**](.md)|  | [optional] 
 **page** | **int**| Page number | [optional] [default to 1]
 **take** | **int**| Items per page | [optional] [default to 10]
 **q** | **String**|  | [optional] 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

