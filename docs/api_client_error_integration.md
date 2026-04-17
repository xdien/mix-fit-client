# API Client Error Handling Integration

This document describes how the shared error UI system integrates with the API client (Dio) to provide automatic error capture and display throughout the application.

## Overview

The API client error handling integration automatically captures HTTP errors, network issues, and other API-related problems, then displays them through the shared error UI system. This provides a consistent error experience across all API calls in the application.

## Architecture

```
API Request → Dio Client → ErrorServiceInterceptor → ErrorService → ErrorStore → UI Components
```

## Components

### 1. ErrorServiceInterceptor

Located at: `frontend/shared/core/lib/error/interceptors/error_service_interceptor.dart`

This Dio interceptor automatically:
- Captures all HTTP errors (4xx, 5xx status codes)
- Captures network errors (timeouts, connection issues, SSL errors)
- Extracts meaningful error messages from API responses
- Creates appropriate error objects (ApiError, NetworkError)
- Sends errors to the ErrorService for display
- Logs requests and responses for debugging
- Sanitizes sensitive data in logs

### 2. RetryService

Located at: `frontend/shared/core/lib/error/services/retry_service.dart`

Provides retry functionality for failed requests:
- Determines if an error is retryable
- Retries requests with original or modified parameters
- Supports delay before retry
- Integrates with error actions for user-initiated retries

### 3. Integration Points

#### Network Module Registration

The interceptor is registered in the network module:

```dart
// frontend/lib/data/di/module/network_module.dart
getIt.registerSingleton<ErrorServiceInterceptor>(ErrorServiceInterceptor());

final dioClient = DioClient(dioConfigs: getIt());
dioClient.addInterceptors([
  getIt<AuthInterceptor>(),
  RetryInterceptor(dio: dioClient.dio, options: const RetryOptions(retries: 3)),
  getIt<ErrorServiceInterceptor>(), // Error handling
  getIt<ErrorInterceptor>(), // Legacy error handling
  getIt<LoggingInterceptor>(),
]);
```

## Error Types Handled

### 1. HTTP Errors (ApiError)

- **4xx Client Errors**: Bad request, unauthorized, forbidden, not found, etc.
- **5xx Server Errors**: Internal server error, bad gateway, service unavailable, etc.
- **Custom Error Messages**: Extracted from API response body
- **Retry Actions**: Available for certain status codes (408, 429, 500, 502, 503, 504)

Example:
```dart
ApiError(
  message: "Validation failed",
  statusCode: 422,
  endpoint: "/api/users",
  method: "POST",
  requestData: {"email": "user@example.com"},
  responseData: {"errors": {"email": ["Email is required"]}},
  actions: [ErrorAction.retry(() => retryRequest())]
)
```

### 2. Network Errors (NetworkError)

- **Connection Timeout**: When connection takes too long to establish
- **Send/Receive Timeout**: When request/response takes too long
- **Connection Error**: No internet connection or server unreachable
- **SSL/Certificate Errors**: Invalid or expired certificates
- **Cancelled Requests**: User or system cancelled requests

Example:
```dart
NetworkError(
  message: "Connection timeout - please check your internet connection",
  networkType: NetworkErrorType.timeout,
  timeout: Duration(seconds: 30),
  url: "https://api.example.com/users",
)
```

## Error Message Extraction

The interceptor intelligently extracts error messages from API responses:

1. **Standard Fields**: Looks for `message`, `error`, `detail`, `description` fields
2. **Validation Errors**: Extracts first validation error from `errors` object
3. **Fallback Messages**: Uses HTTP status code descriptions as fallback

## Data Sanitization

Sensitive data is automatically sanitized in logs:

- **Request Data**: Removes `password`, `token`, `secret`, `key`, `authorization` fields
- **Response Data**: Limits size to prevent memory issues
- **Error Logs**: Filters sensitive information before logging

## Retry Mechanism

### Automatic Retry

The system includes automatic retry for certain errors:
- Configured through `RetryInterceptor` with exponential backoff
- Retries up to 3 times for retryable errors
- Handles timeout and server errors

### User-Initiated Retry

Users can manually retry failed requests:
- Retry actions are added to retryable errors
- Original request parameters are preserved
- Retry can include modifications (headers, query params)

## Usage Examples

### Basic API Call with Error Handling

```dart
// Error handling is automatic - no additional code needed
try {
  final response = await dio.get('/api/users');
  // Handle successful response
} catch (e) {
  // Error is automatically captured and displayed
  // DioException is still thrown for custom handling if needed
}
```

### Custom Error Handling

```dart
try {
  final response = await dio.post('/api/users', data: userData);
} on DioException catch (e) {
  // Error is already captured by interceptor
  // Add custom logic if needed
  if (e.response?.statusCode == 422) {
    // Handle validation errors specifically
  }
}
```

## Testing

### Unit Tests

- `frontend/shared/core/test/error/services/retry_service_test.dart`
- Tests retry logic and error classification

### Integration Tests

- `frontend/test/integration/api_client_error_integration_test.dart`
- Tests interceptor integration with mock responses

### End-to-End Tests

- `frontend/test/integration/api_error_handling_e2e_test.dart`
- Tests complete error flow with real HTTP requests

## Configuration

### Error Display Settings

Users can configure error display through the ErrorStore:
- Show/hide error bar
- Minimize/expand error details
- Auto-dismiss timing
- Network status indicators

### Logging Configuration

Request/response logging can be controlled:
- Enable/disable request logging
- Configure log levels
- Sensitive data filtering

## Best Practices

1. **Let the System Handle Errors**: Don't manually create error dialogs for API errors
2. **Use Specific Error Types**: The system automatically creates appropriate error types
3. **Provide Retry Actions**: For user-recoverable errors, ensure retry actions are available
4. **Test Error Scenarios**: Include error cases in your API integration tests
5. **Monitor Error Logs**: Use the logging output for debugging API issues

## Troubleshooting

### Common Issues

1. **Errors Not Displaying**: Check if ErrorServiceInterceptor is registered in network module
2. **Retry Not Working**: Verify RetryService is properly configured with Dio instance
3. **Sensitive Data in Logs**: Ensure data sanitization is working correctly
4. **Missing Error Actions**: Check if error status codes are in retryable list

### Debug Information

The interceptor logs detailed information:
- Request details (method, URL, data)
- Response details (status, data)
- Error classification and handling
- Retry attempts and results

This information is available in the console during development and can be captured for production debugging.