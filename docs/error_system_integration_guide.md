# Error System Integration Guide

This guide provides step-by-step instructions for integrating the Shared Error UI System into new modules and existing codebases.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Basic Integration](#basic-integration)
3. [Module-Specific Integration](#module-specific-integration)
4. [Advanced Integration Patterns](#advanced-integration-patterns)
5. [Migration from Existing Error Handling](#migration-from-existing-error-handling)
6. [Testing Integration](#testing-integration)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before integrating the error system, ensure you have:

1. **Dependencies installed:**
   ```yaml
   dependencies:
     get_it: ^7.6.0
     mobx: ^2.2.0
     flutter_mobx: ^2.0.6
     dio: ^5.3.0
   
   dev_dependencies:
     build_runner: ^2.4.6
     mobx_codegen: ^2.3.0
   ```

2. **Core error module available:**
   ```dart
   import 'package:core/di/error_module.dart';
   import 'package:core/error/services/error_service_interface.dart';
   import 'package:core/error/stores/error_store.dart';
   ```

3. **GetIt configured in your app:**
   ```dart
   final getIt = GetIt.instance;
   ```

## Basic Integration

### Step 1: Initialize Error Module

Add error module initialization to your app startup:

```dart
// main.dart
import 'package:core/di/error_module.dart';
import 'package:get_it/get_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error module
  await ErrorModule.configureErrorModuleInjection(GetIt.instance);
  
  runApp(MyApp());
}
```

### Step 2: Add Error UI to App Layout

Integrate error display components into your main app layout:

```dart
// app.dart
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  final errorStore = GetIt.instance<ErrorStore>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        // Add error status bar to app bar
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Observer(
            builder: (context) => errorStore.shouldShowErrorBar
                ? ErrorStatusBarWidget(errorStore: errorStore)
                : SizedBox.shrink(),
          ),
        ),
      ),
      body: MyAppContent(),
    );
  }
}
```

### Step 3: Basic Error Handling in Services

Replace existing error handling with the error service:

```dart
// Before
class UserService {
  Future<User?> getUser(String id) async {
    try {
      final response = await dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      print('Error: $e'); // Old way
      return null;
    }
  }
}

// After
class UserService {
  final IErrorService _errorService = GetIt.instance<IErrorService>();

  Future<User?> getUser(String id) async {
    try {
      final response = await dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      _errorService.showApiError(ApiError(
        message: 'Failed to load user',
        statusCode: e.response?.statusCode ?? 0,
        endpoint: '/api/users/$id',
        method: 'GET',
        responseData: e.response?.data,
      ));
      return null;
    }
  }
}
```

## Module-Specific Integration

### Customer Management Module

```dart
// modules/customer/lib/services/customer_service.dart
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/validation_error.dart';

class CustomerService {
  final IErrorService _errorService;
  final Dio _dio;

  CustomerService(this._errorService, this._dio);

  Future<Customer?> createCustomer(CreateCustomerRequest request) async {
    // Client-side validation
    final validationErrors = _validateCustomerRequest(request);
    if (validationErrors.isNotEmpty) {
      _errorService.showValidationError(ValidationError(
        message: 'Please correct the following errors:',
        fieldErrors: validationErrors,
        formId: 'create-customer-form',
      ));
      return null;
    }

    try {
      final response = await _dio.post('/api/customers', data: request.toJson());
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // Server validation errors
        final serverErrors = _parseServerValidationErrors(e.response!.data);
        _errorService.showValidationError(ValidationError(
          message: 'Customer creation failed:',
          fieldErrors: serverErrors,
          formId: 'create-customer-form',
        ));
      } else {
        // Generic API error
        _errorService.showApiError(ApiError(
          message: 'Failed to create customer',
          statusCode: e.response?.statusCode ?? 0,
          endpoint: '/api/customers',
          method: 'POST',
          requestData: request.toJson(),
          responseData: e.response?.data,
        ));
      }
      return null;
    }
  }

  Map<String, List<String>> _validateCustomerRequest(CreateCustomerRequest request) {
    final errors = <String, List<String>>{};

    if (request.name.trim().isEmpty) {
      errors['name'] = ['Customer name is required'];
    }

    if (request.email.trim().isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!_isValidEmail(request.email)) {
      errors['email'] = ['Please enter a valid email address'];
    }

    if (request.phone.trim().isEmpty) {
      errors['phone'] = ['Phone number is required'];
    }

    return errors;
  }
}
```

### Authentication Module

```dart
// modules/auth/lib/services/auth_service.dart
class AuthService {
  final IErrorService _errorService;

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      return AuthResult.success(response.data);
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
          _errorService.showApiError(ApiError(
            message: 'Invalid email or password',
            statusCode: 401,
            endpoint: '/api/auth/login',
            method: 'POST',
            severity: ErrorSeverity.error,
            actions: [
              ErrorAction(
                id: 'forgot_password',
                label: 'Forgot Password?',
                onPressed: () => _navigateToForgotPassword(),
              ),
              ErrorAction(
                id: 'create_account',
                label: 'Create Account',
                onPressed: () => _navigateToSignUp(),
              ),
            ],
          ));
          break;
        case 429:
          _errorService.showApiError(ApiError(
            message: 'Too many login attempts. Please try again later.',
            statusCode: 429,
            endpoint: '/api/auth/login',
            method: 'POST',
            severity: ErrorSeverity.warning,
            actions: [
              ErrorAction(
                id: 'reset_password',
                label: 'Reset Password',
                onPressed: () => _navigateToPasswordReset(),
              ),
            ],
          ));
          break;
        default:
          _errorService.showApiError(ApiError(
            message: 'Login failed. Please try again.',
            statusCode: e.response?.statusCode ?? 0,
            endpoint: '/api/auth/login',
            method: 'POST',
          ));
      }
      return AuthResult.failed();
    }
  }
}
```

### WebSocket Service Integration

```dart
// services/websocket_service.dart
class WebSocketService {
  final IErrorService _errorService;
  IOWebSocketChannel? _channel;

  void connect() {
    try {
      _channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
    } catch (e) {
      _errorService.showError(ClientError(
        message: 'Failed to connect to real-time service',
        stackTrace: e.toString(),
        componentName: 'WebSocketService',
        actions: [
          ErrorAction(
            id: 'retry_connection',
            label: 'Retry Connection',
            isPrimary: true,
            onPressed: () => connect(),
          ),
          ErrorAction(
            id: 'work_offline',
            label: 'Continue Offline',
            onPressed: () => _enableOfflineMode(),
          ),
        ],
      ));
    }
  }

  void _handleError(error) {
    _errorService.showError(ClientError(
      message: 'Real-time connection error',
      stackTrace: error.toString(),
      componentName: 'WebSocketService',
      severity: ErrorSeverity.warning,
      actions: [
        ErrorAction(
          id: 'reconnect',
          label: 'Reconnect',
          isPrimary: true,
          onPressed: () => _reconnect(),
        ),
      ],
    ));
  }

  void _handleDisconnection() {
    _errorService.showError(ClientError(
      message: 'Real-time connection lost',
      stackTrace: 'WebSocket disconnected',
      componentName: 'WebSocketService',
      severity: ErrorSeverity.info,
      actions: [
        ErrorAction(
          id: 'reconnect',
          label: 'Reconnect',
          isPrimary: true,
          onPressed: () => connect(),
        ),
      ],
    ));
  }
}
```

## Advanced Integration Patterns

### Custom Error Interceptor

Create a Dio interceptor that automatically integrates with the error system:

```dart
// interceptors/error_interceptor.dart
class ErrorServiceInterceptor extends Interceptor {
  final IErrorService _errorService;

  ErrorServiceInterceptor(this._errorService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert DioException to appropriate error type
    final error = _convertDioExceptionToAppError(err);
    _errorService.showError(error);
    
    super.onError(err, handler);
  }

  AppError _convertDioExceptionToAppError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: 'Request timed out',
          networkType: NetworkErrorType.timeout,
          timeout: e.type == DioExceptionType.connectionTimeout
              ? e.requestOptions.connectTimeout
              : e.requestOptions.receiveTimeout,
          url: e.requestOptions.path,
        );
      
      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'No internet connection',
          networkType: NetworkErrorType.noConnection,
          url: e.requestOptions.path,
        );
      
      case DioExceptionType.badResponse:
        return ApiError(
          message: _extractErrorMessage(e),
          statusCode: e.response?.statusCode ?? 0,
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          requestData: e.requestOptions.data,
          responseData: e.response?.data,
        );
      
      default:
        return ClientError(
          message: 'An unexpected error occurred',
          stackTrace: e.toString(),
          componentName: 'NetworkClient',
        );
    }
  }
}

// Usage in Dio setup
final dio = Dio();
dio.interceptors.add(ErrorServiceInterceptor(GetIt.instance<IErrorService>()));
```

### Module-Specific Error Store

Create specialized error stores for complex modules:

```dart
// stores/customer_error_store.dart
class CustomerErrorStore extends _CustomerErrorStore with _$CustomerErrorStore {
  CustomerErrorStore(IErrorService errorService) : super(errorService);
}

abstract class _CustomerErrorStore with Store {
  final IErrorService _errorService;

  _CustomerErrorStore(this._errorService);

  @observable
  Map<String, List<String>> fieldErrors = {};

  @observable
  bool isValidating = false;

  @action
  void setFieldErrors(Map<String, List<String>> errors) {
    fieldErrors = errors;
  }

  @action
  void clearFieldError(String field) {
    fieldErrors.remove(field);
    if (fieldErrors.isEmpty) {
      _errorService.clearAllErrors();
    }
  }

  @action
  Future<void> validateCustomerForm(CreateCustomerRequest request) async {
    isValidating = true;
    
    final errors = <String, List<String>>{};
    
    // Perform validation
    if (request.name.trim().isEmpty) {
      errors['name'] = ['Name is required'];
    }
    
    if (request.email.trim().isEmpty) {
      errors['email'] = ['Email is required'];
    }
    
    setFieldErrors(errors);
    
    if (errors.isNotEmpty) {
      _errorService.showValidationError(ValidationError(
        message: 'Please fix the following errors:',
        fieldErrors: errors,
        formId: 'customer-form',
      ));
    }
    
    isValidating = false;
  }
}
```

### Error-Aware Base Widget

Create a base widget class that automatically handles errors:

```dart
// widgets/error_aware_widget.dart
abstract class ErrorAwareWidget extends StatefulWidget {
  const ErrorAwareWidget({Key? key}) : super(key: key);
}

abstract class ErrorAwareState<T extends ErrorAwareWidget> extends State<T> {
  late StreamSubscription _errorSubscription;
  final errorService = GetIt.instance<IErrorService>();
  final errorStore = GetIt.instance<ErrorStore>();

  @override
  void initState() {
    super.initState();
    _errorSubscription = errorService.errorStream.listen(_handleErrors);
  }

  @override
  void dispose() {
    _errorSubscription.cancel();
    super.dispose();
  }

  void _handleErrors(List<AppError> errors) {
    final criticalErrors = errors.where((e) => e.severity == ErrorSeverity.critical);
    for (final error in criticalErrors) {
      _showCriticalErrorDialog(error);
    }
    
    // Allow subclasses to handle specific errors
    onErrorsChanged(errors);
  }

  void _showCriticalErrorDialog(AppError error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialogWidget(
        error: error,
        onDismiss: () {
          Navigator.of(context).pop();
          errorService.clearError(error.id);
        },
      ),
    );
  }

  // Override in subclasses to handle specific error scenarios
  void onErrorsChanged(List<AppError> errors) {}

  // Helper method for showing errors
  void showError(AppError error) {
    errorService.showError(error);
  }

  // Helper method for showing validation errors
  void showValidationError(Map<String, List<String>> fieldErrors, {String? formId}) {
    errorService.showValidationError(ValidationError(
      message: 'Please correct the following errors:',
      fieldErrors: fieldErrors,
      formId: formId,
    ));
  }
}

// Usage
class CustomerFormWidget extends ErrorAwareWidget {
  @override
  _CustomerFormWidgetState createState() => _CustomerFormWidgetState();
}

class _CustomerFormWidgetState extends ErrorAwareState<CustomerFormWidget> {
  @override
  void onErrorsChanged(List<AppError> errors) {
    // Handle customer-specific errors
    final validationErrors = errors.whereType<ValidationError>();
    for (final error in validationErrors) {
      if (error.formId == 'customer-form') {
        _highlightErrorFields(error.fieldErrors);
      }
    }
  }

  void _highlightErrorFields(Map<String, List<String>> fieldErrors) {
    // Highlight fields with errors
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customer Form')),
      body: Column(
        children: [
          // Error status bar
          Observer(
            builder: (context) => errorStore.shouldShowErrorBar
                ? ErrorStatusBarWidget(errorStore: errorStore)
                : SizedBox.shrink(),
          ),
          // Form content
          Expanded(child: _buildForm()),
        ],
      ),
    );
  }
}
```

## Migration from Existing Error Handling

### Step 1: Identify Current Error Handling

Audit your existing codebase for error handling patterns:

```bash
# Search for common error handling patterns
grep -r "showDialog.*error" lib/
grep -r "SnackBar.*error" lib/
grep -r "ScaffoldMessenger" lib/
grep -r "catch.*Exception" lib/
grep -r "try.*catch" lib/
```

### Step 2: Replace Direct UI Error Displays

```dart
// Before: Direct SnackBar usage
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error: Failed to save data'),
    backgroundColor: Colors.red,
  ),
);

// After: Using error service
errorService.showError(ApiError(
  message: 'Failed to save data',
  statusCode: 500,
  endpoint: '/api/data',
  method: 'POST',
));
```

```dart
// Before: Direct Dialog usage
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Error'),
    content: Text('Something went wrong'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);

// After: Using error service
errorService.showError(ClientError(
  message: 'Something went wrong',
  stackTrace: 'Error details here',
  componentName: 'MyWidget',
  severity: ErrorSeverity.critical,
));
```

### Step 3: Centralize Error Handling Logic

```dart
// Before: Scattered error handling
class UserService {
  Future<User?> getUser(String id) async {
    try {
      final response = await dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          _showUserNotFoundDialog();
        } else if (e.response?.statusCode == 401) {
          _redirectToLogin();
        } else {
          _showGenericErrorSnackbar();
        }
      }
      return null;
    }
  }

  void _showUserNotFoundDialog() { /* ... */ }
  void _redirectToLogin() { /* ... */ }
  void _showGenericErrorSnackbar() { /* ... */ }
}

// After: Centralized error handling
class UserService {
  final IErrorService _errorService;

  Future<User?> getUser(String id) async {
    try {
      final response = await dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      _errorService.showApiError(ApiError(
        message: _getErrorMessage(e),
        statusCode: e.response?.statusCode ?? 0,
        endpoint: '/api/users/$id',
        method: 'GET',
        actions: _getErrorActions(e),
      ));
      return null;
    }
  }

  String _getErrorMessage(DioException e) {
    switch (e.response?.statusCode) {
      case 404:
        return 'User not found';
      case 401:
        return 'Authentication required';
      default:
        return 'Failed to load user';
    }
  }

  List<ErrorAction>? _getErrorActions(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return [
          ErrorAction(
            id: 'login',
            label: 'Login',
            isPrimary: true,
            onPressed: () => _redirectToLogin(),
          ),
        ];
      default:
        return null;
    }
  }
}
```

### Step 4: Update Form Validation

```dart
// Before: Manual form validation with direct UI updates
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  String? emailError;
  String? passwordError;

  void _validate() {
    setState(() {
      emailError = _emailController.text.isEmpty ? 'Email is required' : null;
      passwordError = _passwordController.text.isEmpty ? 'Password is required' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: emailError,
          ),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: passwordError,
          ),
        ),
      ],
    );
  }
}

// After: Using error service for validation
class _LoginFormState extends State<LoginForm> {
  final _errorService = GetIt.instance<IErrorService>();

  void _validate() {
    final errors = <String, List<String>>{};

    if (_emailController.text.isEmpty) {
      errors['email'] = ['Email is required'];
    }

    if (_passwordController.text.isEmpty) {
      errors['password'] = ['Password is required'];
    }

    if (errors.isNotEmpty) {
      _errorService.showValidationError(ValidationError(
        message: 'Please correct the following errors:',
        fieldErrors: errors,
        formId: 'login-form',
      ));
    }
  }
}
```

## Testing Integration

### Unit Testing Services with Error Integration

```dart
// test/services/user_service_test.dart
void main() {
  group('UserService with Error Integration', () {
    late MockErrorService mockErrorService;
    late MockDio mockDio;
    late UserService userService;

    setUp(() {
      mockErrorService = MockErrorService();
      mockDio = MockDio();
      userService = UserService(mockErrorService, mockDio);
    });

    test('should show API error when user not found', () async {
      // Arrange
      when(mockDio.get('/api/users/123')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/users/123'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/users/123'),
            statusCode: 404,
          ),
        ),
      );

      // Act
      final result = await userService.getUser('123');

      // Assert
      expect(result, isNull);
      verify(mockErrorService.showApiError(any)).called(1);
      
      final capturedError = verify(mockErrorService.showApiError(captureAny))
          .captured.first as ApiError;
      expect(capturedError.statusCode, equals(404));
      expect(capturedError.message, equals('User not found'));
    });
  });
}
```

### Widget Testing with Error Integration

```dart
// test/widgets/customer_form_test.dart
void main() {
  group('CustomerForm with Error Integration', () {
    late MockErrorService mockErrorService;

    setUp(() {
      mockErrorService = MockErrorService();
      GetIt.instance.registerSingleton<IErrorService>(mockErrorService);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    testWidgets('should show validation error for empty fields', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CustomerFormWidget()),
      );

      // Act
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockErrorService.showValidationError(any)).called(1);
      
      final capturedError = verify(mockErrorService.showValidationError(captureAny))
          .captured.first as ValidationError;
      expect(capturedError.fieldErrors, isNotEmpty);
      expect(capturedError.formId, equals('customer-form'));
    });
  });
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Error Service Not Found

**Problem:**
```
Error: Could not find IErrorService in GetIt
```

**Solution:**
```dart
// Ensure error module is initialized before using
await ErrorModule.configureErrorModuleInjection(GetIt.instance);

// Or check if it's registered
if (!GetIt.instance.isRegistered<IErrorService>()) {
  await ErrorModule.configureErrorModuleInjection(GetIt.instance);
}
```

#### 2. Errors Not Displaying

**Problem:** Errors are being sent to the service but not showing in UI.

**Solution:**
```dart
// Ensure ErrorStatusBarWidget is properly integrated
@override
Widget build(BuildContext context) {
  return Observer( // Make sure to wrap with Observer
    builder: (context) {
      return errorStore.shouldShowErrorBar
          ? ErrorStatusBarWidget(errorStore: errorStore)
          : SizedBox.shrink();
    },
  );
}
```

#### 3. Memory Leaks with Error Subscriptions

**Problem:** Error stream subscriptions not being disposed.

**Solution:**
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _errorSubscription;

  @override
  void initState() {
    super.initState();
    _errorSubscription = errorService.errorStream.listen(_handleErrors);
  }

  @override
  void dispose() {
    _errorSubscription.cancel(); // Important: Cancel subscription
    super.dispose();
  }
}
```

#### 4. Duplicate Error Displays

**Problem:** Same error showing multiple times.

**Solution:**
```dart
// Use error deduplication in service
class MyService {
  String? _lastErrorId;

  void handleError(AppError error) {
    if (_lastErrorId != error.id) {
      errorService.showError(error);
      _lastErrorId = error.id;
    }
  }
}
```

#### 5. Testing Issues with GetIt

**Problem:** GetIt conflicts in tests.

**Solution:**
```dart
void main() {
  setUp(() {
    GetIt.instance.reset(); // Reset before each test
    // Register test dependencies
  });

  tearDown(() {
    GetIt.instance.reset(); // Clean up after each test
  });
}
```

### Performance Considerations

1. **Limit Error Queue Size:** The system automatically limits active errors to 5 to prevent memory issues.

2. **Dispose Subscriptions:** Always dispose of error stream subscriptions in widget dispose methods.

3. **Use Observer Sparingly:** Only wrap widgets that actually need to react to error state changes with Observer.

4. **Batch Error Updates:** If showing multiple related errors, consider batching them into a single validation error.

### Best Practices Summary

1. **Initialize Early:** Set up the error module in your app's main function.

2. **Use Appropriate Error Types:** Choose the right error type (ApiError, ValidationError, etc.) for each scenario.

3. **Provide Meaningful Actions:** Include relevant actions that help users resolve errors.

4. **Test Error Scenarios:** Write tests for both success and error cases.

5. **Handle Edge Cases:** Consider network failures, timeouts, and unexpected errors.

6. **Maintain Consistency:** Use the error system consistently across all modules.

This integration guide should help you successfully integrate the Shared Error UI System into your modules and migrate from existing error handling patterns.