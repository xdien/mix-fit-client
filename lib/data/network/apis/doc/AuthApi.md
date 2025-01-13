# api_client.api.AuthApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authControllerGetCurrentUser**](AuthApi.md#authcontrollergetcurrentuser) | **GET** /v1/auth/me | 
[**authControllerUserLogin**](AuthApi.md#authcontrolleruserlogin) | **POST** /auth/login | 
[**authControllerUserRegister**](AuthApi.md#authcontrolleruserregister) | **POST** /auth/register | Register new user


# **authControllerGetCurrentUser**
> UserDto authControllerGetCurrentUser()



### Example
```dart
import 'package:api_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();

try {
    final result = api_instance.authControllerGetCurrentUser();
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authControllerGetCurrentUser: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserDto**](UserDto.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerUserLogin**
> LoginPayloadDto authControllerUserLogin(userLoginDto)



### Example
```dart
import 'package:api_client/api.dart';

final api_instance = AuthApi();
final userLoginDto = UserLoginDto(); // UserLoginDto | 

try {
    final result = api_instance.authControllerUserLogin(userLoginDto);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authControllerUserLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userLoginDto** | [**UserLoginDto**](UserLoginDto.md)|  | 

### Return type

[**LoginPayloadDto**](LoginPayloadDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerUserRegister**
> UserDto authControllerUserRegister(username, email, password, fullName, phone, avatar)

Register new user

### Example
```dart
import 'package:api_client/api.dart';

final api_instance = AuthApi();
final username = username_example; // String | 
final email = email_example; // String | 
final password = password_example; // String | 
final fullName = fullName_example; // String | 
final phone = phone_example; // String | 
final avatar = BINARY_DATA_HERE; // MultipartFile | User avatar file

try {
    final result = api_instance.authControllerUserRegister(username, email, password, fullName, phone, avatar);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authControllerUserRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**|  | 
 **email** | **String**|  | 
 **password** | **String**|  | 
 **fullName** | **String**|  | [optional] 
 **phone** | **String**|  | [optional] 
 **avatar** | **MultipartFile**| User avatar file | [optional] 

### Return type

[**UserDto**](UserDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

