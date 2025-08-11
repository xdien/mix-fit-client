# Error System Usage Examples

This document provides practical examples of how to use the Shared Error UI System in different scenarios.

## Table of Contents

1. [API Error Handling](#api-error-handling)
2. [Form Validation Errors](#form-validation-errors)
3. [Network Error Handling](#network-error-handling)
4. [Authentication Errors](#authentication-errors)
5. [Custom Error Scenarios](#custom-error-scenarios)
6. [Integration Patterns](#integration-patterns)
7. [Testing Examples](#testing-examples)

## API Error Handling

### Basic API Error

```dart
class UserService {
  final IErrorService _errorService;
  final Dio _dio;

  UserService(this._errorService, this._dio);

  Future<User?> getUser(String userId) async {
    try {
      final response = await _dio.get('/api/users/$userId');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      _errorService.showApiError(ApiError(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode ?? 0,
        endpoint: '/api/users/$userId',
        method: 'GET',
        responseData: e.response?.data,
      ));
      return null;
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['message'] ?? data['error'] ?? 'An error occurred';
    }
    return e.message ?? 'Network error';
  }
}
```

### API Error with Retry Logic

```dart
class DataService {
  final IErrorService _errorService;
  final Dio _dio;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  Future<List<Item>> fetchItems() async {
    try {
      final response = await _dio.get('/api/items');
      _retryCount = 0; // Reset on success
      return (response.data as List)
          .map((json) => Item.fromJson(json))
          .toList();
    } on DioException catch (e) {
      final canRetry = _retryCount < _maxRetries && _isRetryableError(e);
      
      _errorService.showApiError(ApiError(
        message: 'Failed to load items',
        statusCode: e.response?.statusCode ?? 0,
        endpoint: '/api/items',
        method: 'GET',
        responseData: e.response?.data,
        actions: canRetry ? [
          ErrorAction(
            id: 'retry',
            label: 'Retry (${_maxRetries - _retryCount} attempts left)',
            isPrimary: true,
            onPressed: () {
              _retryCount++;
              fetchItems();
            },
          ),
        ] : null,
      ));
      return [];
    }
  }

  bool _isRetryableError(DioException e) {
    final statusCode = e.response?.statusCode;
    return statusCode == null || statusCode >= 500 || statusCode == 408;
  }
}
```

### API Error with Custom Actions

```dart
class OrderService {
  final IErrorService _errorService;

  Future<void> createOrder(Order order) async {
    try {
      await _dio.post('/api/orders', data: order.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Conflict - item out of stock
        _errorService.showApiError(ApiError(
          message: 'Some items in your order are no longer available',
          statusCode: 409,
          endpoint: '/api/orders',
          method: 'POST',
          requestData: order.toJson(),
          responseData: e.response?.data,
          actions: [
            ErrorAction(
              id: 'update_cart',
              label: 'Update Cart',
              isPrimary: true,
              onPressed: () => _updateCartWithAvailableItems(order),
            ),
            ErrorAction(
              id: 'save_for_later',
              label: 'Save for Later',
              onPressed: () => _saveOrderForLater(order),
            ),
            ErrorAction(
              id: 'cancel',
              label: 'Cancel Order',
              onPressed: () => _cancelOrder(),
            ),
          ],
        ));
      } else {
        // Generic error
        _errorService.showApiError(ApiError(
          message: 'Failed to create order',
          statusCode: e.response?.statusCode ?? 0,
          endpoint: '/api/orders',
          method: 'POST',
          requestData: order.toJson(),
          responseData: e.response?.data,
        ));
      }
    }
  }
}
```

## Form Validation Errors

### Basic Form Validation

```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _errorService = GetIt.instance<IErrorService>();

  void _validateAndSubmit() {
    final errors = <String, List<String>>{};

    // Email validation
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!_isValidEmail(email)) {
      errors['email'] = ['Please enter a valid email address'];
    }

    // Password validation
    final password = _passwordController.text;
    if (password.isEmpty) {
      errors['password'] = ['Password is required'];
    } else if (password.length < 8) {
      errors['password'] = ['Password must be at least 8 characters'];
    }

    if (errors.isNotEmpty) {
      _errorService.showValidationError(ValidationError(
        message: 'Please correct the following errors:',
        fieldErrors: errors,
        formId: 'login-form',
        actions: [
          ErrorAction(
            id: 'fix_fields',
            label: 'Fix Fields',
            isPrimary: true,
            onPressed: () => _focusFirstErrorField(errors),
          ),
        ],
      ));
      return;
    }

    _submitForm();
  }

  void _focusFirstErrorField(Map<String, List<String>> errors) {
    if (errors.containsKey('email')) {
      _emailController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _emailController.text.length,
      );
      FocusScope.of(context).requestFocus(_emailFocusNode);
    } else if (errors.containsKey('password')) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

### Complex Form Validation with Server-Side Errors

```dart
class UserRegistrationService {
  final IErrorService _errorService;

  Future<bool> registerUser(UserRegistrationData data) async {
    // Client-side validation first
    final clientErrors = _validateClientSide(data);
    if (clientErrors.isNotEmpty) {
      _errorService.showValidationError(ValidationError(
        message: 'Please fix the following issues:',
        fieldErrors: clientErrors,
        formId: 'user-registration',
        severity: ErrorSeverity.warning,
      ));
      return false;
    }

    try {
      await _dio.post('/api/users/register', data: data.toJson());
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // Server validation errors
        final serverErrors = _parseServerValidationErrors(e.response!.data);
        _errorService.showValidationError(ValidationError(
          message: 'Registration failed due to validation errors:',
          fieldErrors: serverErrors,
          formId: 'user-registration',
          severity: ErrorSeverity.error,
          actions: [
            ErrorAction(
              id: 'fix_and_retry',
              label: 'Fix and Retry',
              isPrimary: true,
              onPressed: () => _highlightErrorFields(serverErrors),
            ),
            ErrorAction(
              id: 'contact_support',
              label: 'Contact Support',
              onPressed: () => _contactSupport(),
            ),
          ],
        ));
      } else {
        // Other API errors
        _errorService.showApiError(ApiError(
          message: 'Registration failed',
          statusCode: e.response?.statusCode ?? 0,
          endpoint: '/api/users/register',
          method: 'POST',
          requestData: data.toJson(),
          responseData: e.response?.data,
        ));
      }
      return false;
    }
  }

  Map<String, List<String>> _validateClientSide(UserRegistrationData data) {
    final errors = <String, List<String>>{};

    // Email validation
    if (data.email.isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!_isValidEmail(data.email)) {
      errors['email'] = ['Invalid email format'];
    }

    // Password validation
    if (data.password.isEmpty) {
      errors['password'] = ['Password is required'];
    } else {
      final passwordErrors = <String>[];
      if (data.password.length < 8) {
        passwordErrors.add('Must be at least 8 characters');
      }
      if (!RegExp(r'[A-Z]').hasMatch(data.password)) {
        passwordErrors.add('Must contain at least one uppercase letter');
      }
      if (!RegExp(r'[a-z]').hasMatch(data.password)) {
        passwordErrors.add('Must contain at least one lowercase letter');
      }
      if (!RegExp(r'[0-9]').hasMatch(data.password)) {
        passwordErrors.add('Must contain at least one number');
      }
      if (passwordErrors.isNotEmpty) {
        errors['password'] = passwordErrors;
      }
    }

    // Confirm password
    if (data.confirmPassword != data.password) {
      errors['confirmPassword'] = ['Passwords do not match'];
    }

    return errors;
  }

  Map<String, List<String>> _parseServerValidationErrors(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('errors')) {
      final serverErrors = responseData['errors'] as Map<String, dynamic>;
      return serverErrors.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.cast<String>());
        } else if (value is String) {
          return MapEntry(key, [value]);
        }
        return MapEntry(key, ['Invalid value']);
      });
    }
    return {};
  }
}
```

## Network Error Handling

### Connection Timeout Handling

```dart
class NetworkService {
  final IErrorService _errorService;
  final Dio _dio;

  NetworkService(this._errorService, this._dio) {
    _dio.options.connectTimeout = Duration(seconds: 10);
    _dio.options.receiveTimeout = Duration(seconds: 30);
  }

  Future<T?> makeRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _dio.get(endpoint);
      return fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        _errorService.showNetworkError(NetworkError(
          message: 'Connection timeout. Please check your internet connection.',
          networkType: NetworkErrorType.timeout,
          timeout: _dio.options.connectTimeout,
          url: endpoint,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => makeRequest(endpoint, fromJson),
            ),
            ErrorAction(
              id: 'check_connection',
              label: 'Check Connection',
              onPressed: () => _checkNetworkConnection(),
            ),
          ],
        ));
      } else if (e.type == DioExceptionType.receiveTimeout) {
        _errorService.showNetworkError(NetworkError(
          message: 'Server is taking too long to respond.',
          networkType: NetworkErrorType.timeout,
          timeout: _dio.options.receiveTimeout,
          url: endpoint,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => makeRequest(endpoint, fromJson),
            ),
            ErrorAction(
              id: 'try_later',
              label: 'Try Later',
              onPressed: () => _scheduleRetryLater(endpoint, fromJson),
            ),
          ],
        ));
      } else {
        _handleGenericNetworkError(e, endpoint);
      }
      return null;
    }
  }

  void _checkNetworkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _errorService.showNetworkError(NetworkError(
        message: 'No internet connection detected.',
        networkType: NetworkErrorType.noConnection,
        actions: [
          ErrorAction(
            id: 'open_settings',
            label: 'Open Settings',
            isPrimary: true,
            onPressed: () => _openNetworkSettings(),
          ),
        ],
      ));
    } else {
      _errorService.showNetworkError(NetworkError(
        message: 'Internet connection detected. You can try your request again.',
        networkType: NetworkErrorType.noConnection,
        severity: ErrorSeverity.info,
      ));
    }
  }
}
```

### Offline Mode Handling

```dart
class OfflineCapableService {
  final IErrorService _errorService;
  final LocalStorage _localStorage;
  bool _isOffline = false;

  Future<List<Item>> getItems() async {
    if (_isOffline) {
      return _getItemsFromCache();
    }

    try {
      final items = await _getItemsFromServer();
      await _cacheItems(items);
      return items;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _isOffline = true;
        _errorService.showNetworkError(NetworkError(
          message: 'You\'re currently offline. Showing cached data.',
          networkType: NetworkErrorType.noConnection,
          severity: ErrorSeverity.info,
          actions: [
            ErrorAction(
              id: 'retry_online',
              label: 'Try to Go Online',
              isPrimary: true,
              onPressed: () => _attemptReconnection(),
            ),
            ErrorAction(
              id: 'work_offline',
              label: 'Continue Offline',
              onPressed: () => _enterOfflineMode(),
            ),
          ],
        ));
        return _getItemsFromCache();
      }
      rethrow;
    }
  }

  Future<void> _attemptReconnection() async {
    try {
      await _dio.get('/api/health');
      _isOffline = false;
      _errorService.clearAllErrors();
      _errorService.showNetworkError(NetworkError(
        message: 'Connection restored! Syncing data...',
        networkType: NetworkErrorType.noConnection,
        severity: ErrorSeverity.info,
      ));
      await _syncOfflineChanges();
    } catch (e) {
      _errorService.showNetworkError(NetworkError(
        message: 'Still unable to connect. Please check your internet connection.',
        networkType: NetworkErrorType.noConnection,
        actions: [
          ErrorAction(
            id: 'retry_again',
            label: 'Try Again',
            onPressed: () => _attemptReconnection(),
          ),
        ],
      ));
    }
  }
}
```

## Authentication Errors

### Token Expiration Handling

```dart
class AuthService {
  final IErrorService _errorService;
  final TokenStorage _tokenStorage;

  Future<void> handleAuthError(DioException e) async {
    if (e.response?.statusCode == 401) {
      final errorData = e.response?.data;
      
      if (errorData is Map<String, dynamic> && 
          errorData['error'] == 'token_expired') {
        // Token expired - try to refresh
        _errorService.showApiError(ApiError(
          message: 'Your session has expired',
          statusCode: 401,
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          severity: ErrorSeverity.warning,
          actions: [
            ErrorAction(
              id: 'refresh_token',
              label: 'Refresh Session',
              isPrimary: true,
              onPressed: () => _refreshToken(),
            ),
            ErrorAction(
              id: 'login_again',
              label: 'Login Again',
              onPressed: () => _redirectToLogin(),
            ),
          ],
        ));
      } else {
        // Invalid credentials
        _errorService.showApiError(ApiError(
          message: 'Authentication failed. Please check your credentials.',
          statusCode: 401,
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          severity: ErrorSeverity.error,
          actions: [
            ErrorAction(
              id: 'login_again',
              label: 'Login Again',
              isPrimary: true,
              onPressed: () => _redirectToLogin(),
            ),
            ErrorAction(
              id: 'forgot_password',
              label: 'Forgot Password?',
              onPressed: () => _showForgotPassword(),
            ),
          ],
        ));
      }
    } else if (e.response?.statusCode == 403) {
      // Insufficient permissions
      _errorService.showApiError(ApiError(
        message: 'You don\'t have permission to perform this action.',
        statusCode: 403,
        endpoint: e.requestOptions.path,
        method: e.requestOptions.method,
        severity: ErrorSeverity.error,
        actions: [
          ErrorAction(
            id: 'contact_admin',
            label: 'Contact Administrator',
            isPrimary: true,
            onPressed: () => _contactAdmin(),
          ),
          ErrorAction(
            id: 'go_back',
            label: 'Go Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ));
    }
  }

  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      final response = await _dio.post('/api/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      
      await _tokenStorage.saveTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );
      
      _errorService.clearAllErrors();
      _errorService.showApiError(ApiError(
        message: 'Session refreshed successfully',
        statusCode: 200,
        endpoint: '/api/auth/refresh',
        method: 'POST',
        severity: ErrorSeverity.info,
      ));
    } catch (e) {
      _errorService.showApiError(ApiError(
        message: 'Failed to refresh session. Please login again.',
        statusCode: 401,
        endpoint: '/api/auth/refresh',
        method: 'POST',
        severity: ErrorSeverity.error,
        actions: [
          ErrorAction(
            id: 'login_again',
            label: 'Login Again',
            isPrimary: true,
            onPressed: () => _redirectToLogin(),
          ),
        ],
      ));
    }
  }
}
```

## Custom Error Scenarios

### Business Logic Errors

```dart
class PaymentService {
  final IErrorService _errorService;

  Future<PaymentResult> processPayment(PaymentRequest request) async {
    try {
      final response = await _dio.post('/api/payments', data: request.toJson());
      return PaymentResult.fromJson(response.data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;

      switch (statusCode) {
        case 402: // Payment Required
          _handleInsufficientFunds(errorData);
          break;
        case 409: // Conflict
          _handlePaymentConflict(errorData);
          break;
        case 422: // Unprocessable Entity
          _handlePaymentValidationError(errorData);
          break;
        default:
          _handleGenericPaymentError(e);
      }
      
      return PaymentResult.failed();
    }
  }

  void _handleInsufficientFunds(dynamic errorData) {
    final availableBalance = errorData?['available_balance'] ?? 0.0;
    final requiredAmount = errorData?['required_amount'] ?? 0.0;
    final shortfall = requiredAmount - availableBalance;

    _errorService.showApiError(ApiError(
      message: 'Insufficient funds. You need \$${shortfall.toStringAsFixed(2)} more.',
      statusCode: 402,
      endpoint: '/api/payments',
      method: 'POST',
      severity: ErrorSeverity.warning,
      actions: [
        ErrorAction(
          id: 'add_funds',
          label: 'Add Funds',
          isPrimary: true,
          onPressed: () => _navigateToAddFunds(shortfall),
        ),
        ErrorAction(
          id: 'use_different_method',
          label: 'Use Different Payment Method',
          onPressed: () => _showPaymentMethods(),
        ),
        ErrorAction(
          id: 'save_for_later',
          label: 'Save for Later',
          onPressed: () => _savePaymentForLater(),
        ),
      ],
    ));
  }

  void _handlePaymentConflict(dynamic errorData) {
    final conflictType = errorData?['conflict_type'];
    
    if (conflictType == 'duplicate_transaction') {
      _errorService.showApiError(ApiError(
        message: 'This transaction has already been processed.',
        statusCode: 409,
        endpoint: '/api/payments',
        method: 'POST',
        severity: ErrorSeverity.warning,
        actions: [
          ErrorAction(
            id: 'view_transaction',
            label: 'View Transaction',
            isPrimary: true,
            onPressed: () => _viewExistingTransaction(errorData?['transaction_id']),
          ),
          ErrorAction(
            id: 'create_new',
            label: 'Create New Transaction',
            onPressed: () => _createNewTransaction(),
          ),
        ],
      ));
    } else if (conflictType == 'concurrent_modification') {
      _errorService.showApiError(ApiError(
        message: 'This payment was modified by another process. Please refresh and try again.',
        statusCode: 409,
        endpoint: '/api/payments',
        method: 'POST',
        severity: ErrorSeverity.error,
        actions: [
          ErrorAction(
            id: 'refresh_and_retry',
            label: 'Refresh and Retry',
            isPrimary: true,
            onPressed: () => _refreshAndRetry(),
          ),
        ],
      ));
    }
  }
}
```

### File Upload Errors

```dart
class FileUploadService {
  final IErrorService _errorService;

  Future<UploadResult> uploadFile(File file) async {
    // Validate file before upload
    final validationError = _validateFile(file);
    if (validationError != null) {
      _errorService.showValidationError(validationError);
      return UploadResult.failed();
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _dio.post('/api/upload', data: formData);
      return UploadResult.fromJson(response.data);
    } on DioException catch (e) {
      _handleUploadError(e, file);
      return UploadResult.failed();
    }
  }

  ValidationError? _validateFile(File file) {
    final errors = <String, List<String>>{};
    
    // Check file size (10MB limit)
    final fileSizeInMB = file.lengthSync() / (1024 * 1024);
    if (fileSizeInMB > 10) {
      errors['file'] = ['File size must be less than 10MB (current: ${fileSizeInMB.toStringAsFixed(1)}MB)'];
    }

    // Check file type
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx'];
    final fileExtension = path.extension(file.path).toLowerCase();
    if (!allowedExtensions.contains(fileExtension)) {
      errors['file'] = [
        'File type not supported. Allowed types: ${allowedExtensions.join(', ')}'
      ];
    }

    if (errors.isNotEmpty) {
      return ValidationError(
        message: 'File validation failed:',
        fieldErrors: errors,
        formId: 'file-upload',
        actions: [
          ErrorAction(
            id: 'choose_different_file',
            label: 'Choose Different File',
            isPrimary: true,
            onPressed: () => _chooseFile(),
          ),
          ErrorAction(
            id: 'compress_file',
            label: 'Compress File',
            onPressed: () => _showCompressionOptions(),
          ),
        ],
      );
    }

    return null;
  }

  void _handleUploadError(DioException e, File file) {
    final statusCode = e.response?.statusCode;
    
    switch (statusCode) {
      case 413: // Payload Too Large
        _errorService.showApiError(ApiError(
          message: 'File is too large for upload.',
          statusCode: 413,
          endpoint: '/api/upload',
          method: 'POST',
          actions: [
            ErrorAction(
              id: 'compress_file',
              label: 'Compress File',
              isPrimary: true,
              onPressed: () => _compressAndRetry(file),
            ),
            ErrorAction(
              id: 'choose_smaller_file',
              label: 'Choose Smaller File',
              onPressed: () => _chooseFile(),
            ),
          ],
        ));
        break;
        
      case 415: // Unsupported Media Type
        _errorService.showApiError(ApiError(
          message: 'File type not supported by the server.',
          statusCode: 415,
          endpoint: '/api/upload',
          method: 'POST',
          actions: [
            ErrorAction(
              id: 'convert_file',
              label: 'Convert File',
              isPrimary: true,
              onPressed: () => _showConversionOptions(file),
            ),
            ErrorAction(
              id: 'choose_different_file',
              label: 'Choose Different File',
              onPressed: () => _chooseFile(),
            ),
          ],
        ));
        break;
        
      default:
        _errorService.showApiError(ApiError(
          message: 'Failed to upload file. Please try again.',
          statusCode: statusCode ?? 0,
          endpoint: '/api/upload',
          method: 'POST',
          actions: [
            ErrorAction(
              id: 'retry_upload',
              label: 'Retry Upload',
              isPrimary: true,
              onPressed: () => uploadFile(file),
            ),
          ],
        ));
    }
  }
}
```

## Integration Patterns

### Service Layer Integration

```dart
abstract class BaseService {
  final IErrorService _errorService;
  final Dio _dio;

  BaseService(this._errorService, this._dio);

  Future<T?> safeApiCall<T>(
    Future<Response> Function() apiCall,
    T Function(dynamic data) parser, {
    String? customErrorMessage,
    List<ErrorAction>? customActions,
  }) async {
    try {
      final response = await apiCall();
      return parser(response.data);
    } on DioException catch (e) {
      _handleApiError(e, customErrorMessage, customActions);
      return null;
    } catch (e) {
      _errorService.showError(ClientError(
        message: customErrorMessage ?? 'An unexpected error occurred',
        stackTrace: e.toString(),
        componentName: runtimeType.toString(),
      ));
      return null;
    }
  }

  void _handleApiError(
    DioException e,
    String? customMessage,
    List<ErrorAction>? customActions,
  ) {
    _errorService.showApiError(ApiError(
      message: customMessage ?? _extractErrorMessage(e),
      statusCode: e.response?.statusCode ?? 0,
      endpoint: e.requestOptions.path,
      method: e.requestOptions.method,
      requestData: e.requestOptions.data,
      responseData: e.response?.data,
      actions: customActions,
    ));
  }
}

// Usage in specific services
class UserService extends BaseService {
  UserService(super.errorService, super.dio);

  Future<User?> createUser(CreateUserRequest request) {
    return safeApiCall(
      () => _dio.post('/api/users', data: request.toJson()),
      (data) => User.fromJson(data),
      customErrorMessage: 'Failed to create user account',
      customActions: [
        ErrorAction(
          id: 'try_different_email',
          label: 'Try Different Email',
          onPressed: () => _suggestAlternativeEmail(request.email),
        ),
      ],
    );
  }
}
```

### Widget Integration Pattern

```dart
class ErrorAwareWidget extends StatefulWidget {
  @override
  _ErrorAwareWidgetState createState() => _ErrorAwareWidgetState();
}

class _ErrorAwareWidgetState extends State<ErrorAwareWidget> {
  final _errorService = GetIt.instance<IErrorService>();
  final _errorStore = GetIt.instance<ErrorStore>();
  late StreamSubscription _errorSubscription;

  @override
  void initState() {
    super.initState();
    _errorSubscription = _errorService.errorStream.listen(_handleErrors);
  }

  @override
  void dispose() {
    _errorSubscription.cancel();
    super.dispose();
  }

  void _handleErrors(List<AppError> errors) {
    // Handle widget-specific error logic
    final criticalErrors = errors.where((e) => e.severity == ErrorSeverity.critical);
    if (criticalErrors.isNotEmpty) {
      _showCriticalErrorDialog(criticalErrors.first);
    }
  }

  void _showCriticalErrorDialog(AppError error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialogWidget(
        error: error,
        onDismiss: () {
          Navigator.of(context).pop();
          _errorService.clearError(error.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Observer(
            builder: (context) => _errorStore.shouldShowErrorBar
                ? ErrorStatusBarWidget(errorStore: _errorStore)
                : SizedBox.shrink(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMainContent()),
          Observer(
            builder: (context) => _errorStore.hasErrors
                ? _buildErrorSummary()
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSummary() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Theme.of(context).errorColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).errorColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_errorStore.activeErrors.length} error(s) need attention',
              style: TextStyle(color: Theme.of(context).errorColor),
            ),
          ),
          TextButton(
            onPressed: () => _showAllErrors(),
            child: Text('View All'),
          ),
        ],
      ),
    );
  }
}
```

## Testing Examples

### Unit Testing Error Service

```dart
void main() {
  group('ErrorService Tests', () {
    late MockErrorStore mockErrorStore;
    late ErrorService errorService;

    setUp(() {
      mockErrorStore = MockErrorStore();
      errorService = ErrorService(mockErrorStore);
    });

    test('should add error to store when showError is called', () {
      // Arrange
      final error = ApiError(
        message: 'Test error',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      // Act
      errorService.showError(error);

      // Assert
      verify(mockErrorStore.addError(error)).called(1);
    });

    test('should clear specific error when clearError is called', () {
      // Arrange
      const errorId = 'test-error-id';

      // Act
      errorService.clearError(errorId);

      // Assert
      verify(mockErrorStore.removeError(errorId)).called(1);
    });

    test('should clear all errors when clearAllErrors is called', () {
      // Act
      errorService.clearAllErrors();

      // Assert
      verify(mockErrorStore.clearAllErrors()).called(1);
    });
  });
}
```

### Widget Testing with Errors

```dart
void main() {
  group('ErrorStatusBarWidget Tests', () {
    late MockErrorStore mockErrorStore;

    setUp(() {
      mockErrorStore = MockErrorStore();
    });

    testWidgets('should display error message when error is present', (tester) async {
      // Arrange
      final error = ApiError(
        message: 'Test error message',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      when(mockErrorStore.hasErrors).thenReturn(true);
      when(mockErrorStore.priorityError).thenReturn(error);
      when(mockErrorStore.shouldShowErrorBar).thenReturn(true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStatusBarWidget(errorStore: mockErrorStore),
          ),
        ),
      );

      // Assert
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('should call retry action when retry button is pressed', (tester) async {
      // Arrange
      bool retryPressed = false;
      final error = ApiError(
        message: 'Test error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction(
            id: 'retry',
            label: 'Retry',
            onPressed: () => retryPressed = true,
          ),
        ],
      );

      when(mockErrorStore.hasErrors).thenReturn(true);
      when(mockErrorStore.priorityError).thenReturn(error);
      when(mockErrorStore.shouldShowErrorBar).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStatusBarWidget(errorStore: mockErrorStore),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert
      expect(retryPressed, isTrue);
    });
  });
}
```

### Integration Testing

```dart
void main() {
  group('Error System Integration Tests', () {
    late GetIt getIt;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('should display API error in status bar', (tester) async {
      // Arrange
      final error = ApiError(
        message: 'Integration test error',
        statusCode: 500,
        endpoint: '/api/integration-test',
        method: 'GET',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ErrorStatusBarWidget(errorStore: errorStore),
                ElevatedButton(
                  onPressed: () => errorService.showError(error),
                  child: Text('Trigger Error'),
                ),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Integration test error'), findsOneWidget);
      expect(errorStore.hasErrors, isTrue);
      expect(errorStore.activeErrors.length, equals(1));
    });
  });
}
```

This comprehensive set of examples demonstrates how to use the Shared Error UI System in various real-world scenarios, from basic API errors to complex business logic errors, with proper testing strategies.