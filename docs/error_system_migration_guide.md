# Error System Migration Guide

This guide helps you migrate from existing error handling patterns to the new Shared Error UI System.

## Table of Contents

1. [Migration Overview](#migration-overview)
2. [Pre-Migration Assessment](#pre-migration-assessment)
3. [Step-by-Step Migration](#step-by-step-migration)
4. [Common Migration Patterns](#common-migration-patterns)
5. [Backward Compatibility](#backward-compatibility)
6. [Testing Migration](#testing-migration)
7. [Rollback Strategy](#rollback-strategy)

## Migration Overview

### What's Changing

**Before (Legacy):**
- Scattered error handling across widgets
- Direct use of SnackBar, AlertDialog, etc.
- Inconsistent error messaging
- No centralized error management
- Manual error state management

**After (New System):**
- Centralized error service
- Consistent error UI components
- Automatic error prioritization
- Reactive error state management
- Standardized error types and actions

### Benefits of Migration

1. **Consistency:** Uniform error display across the app
2. **Maintainability:** Centralized error handling logic
3. **User Experience:** Better error messaging and actions
4. **Accessibility:** Built-in accessibility features
5. **Testing:** Easier to test error scenarios

## Pre-Migration Assessment

### 1. Audit Current Error Handling

Run these commands to identify existing error handling patterns:

```bash
# Find direct SnackBar usage
grep -r "SnackBar" lib/ --include="*.dart" | grep -v "import"

# Find AlertDialog usage for errors
grep -r "AlertDialog" lib/ --include="*.dart" | grep -i "error"

# Find ScaffoldMessenger usage
grep -r "ScaffoldMessenger" lib/ --include="*.dart"

# Find try-catch blocks
grep -r "catch" lib/ --include="*.dart" | wc -l

# Find error-related state variables
grep -r "error" lib/ --include="*.dart" | grep -E "(bool|String).*error"
```

### 2. Categorize Error Handling Patterns

Create an inventory of your current error handling:

```dart
// Create this assessment file: assessment/error_audit.dart
class ErrorAudit {
  static void auditCurrentErrorHandling() {
    print('=== ERROR HANDLING AUDIT ===');
    
    // 1. Direct UI Error Displays
    final directUIErrors = [
      'SnackBar usage in UserService',
      'AlertDialog in PaymentWidget',
      'Custom error widgets in FormValidator',
    ];
    
    // 2. Error State Management
    final errorStatePatterns = [
      'isLoading/hasError pattern in UserStore',
      'errorMessage String in LoginForm',
      'ValidationResult class in FormValidator',
    ];
    
    // 3. API Error Handling
    final apiErrorPatterns = [
      'try-catch in UserService.getUser()',
      'DioException handling in ApiClient',
      'HTTP status code checking in BaseService',
    ];
    
    // 4. Form Validation Errors
    final validationPatterns = [
      'TextFormField validator functions',
      'Form.validate() usage',
      'Custom validation error display',
    ];
    
    _printAuditResults(directUIErrors, errorStatePatterns, apiErrorPatterns, validationPatterns);
  }
  
  static void _printAuditResults(
    List<String> directUI,
    List<String> stateManagement,
    List<String> apiErrors,
    List<String> validation,
  ) {
    print('Direct UI Errors (${directUI.length}):');
    directUI.forEach((item) => print('  - $item'));
    
    print('\nError State Management (${stateManagement.length}):');
    stateManagement.forEach((item) => print('  - $item'));
    
    print('\nAPI Error Handling (${apiErrors.length}):');
    apiErrors.forEach((item) => print('  - $item'));
    
    print('\nForm Validation (${validation.length}):');
    validation.forEach((item) => print('  - $item'));
    
    print('\nTotal Error Handling Locations: ${directUI.length + stateManagement.length + apiErrors.length + validation.length}');
  }
}
```

### 3. Prioritize Migration Areas

Rank areas by impact and complexity:

```dart
enum MigrationPriority {
  high,    // Critical user flows, frequently used features
  medium,  // Important but less frequent features
  low,     // Edge cases, admin features
}

class MigrationPlan {
  static final Map<String, MigrationPriority> areas = {
    // High Priority - Core user flows
    'User Authentication': MigrationPriority.high,
    'API Error Handling': MigrationPriority.high,
    'Form Validation': MigrationPriority.high,
    
    // Medium Priority - Important features
    'Network Error Handling': MigrationPriority.medium,
    'File Upload Errors': MigrationPriority.medium,
    'Payment Processing': MigrationPriority.medium,
    
    // Low Priority - Edge cases
    'Admin Panel Errors': MigrationPriority.low,
    'Debug/Development Errors': MigrationPriority.low,
    'Legacy Feature Errors': MigrationPriority.low,
  };
}
```

## Step-by-Step Migration

### Phase 1: Setup and Infrastructure

#### Step 1.1: Install Dependencies

```yaml
# pubspec.yaml
dependencies:
  get_it: ^7.6.0
  mobx: ^2.2.0
  flutter_mobx: ^2.0.6
  
dev_dependencies:
  build_runner: ^2.4.6
  mobx_codegen: ^2.3.0
```

#### Step 1.2: Initialize Error System

```dart
// main.dart
import 'package:core/di/error_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error system
  await ErrorModule.configureErrorModuleInjection(GetIt.instance);
  
  runApp(MyApp());
}
```

#### Step 1.3: Add Error UI to Main Layout

```dart
// app.dart - Add error status bar to main layout
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorStore = GetIt.instance<ErrorStore>();
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
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
      ),
    );
  }
}
```

### Phase 2: Migrate High-Priority Areas

#### Step 2.1: Migrate API Error Handling

**Before:**
```dart
class UserService {
  Future<User?> getUser(String id) async {
    try {
      final response = await dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      // Old way - direct UI manipulation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
}
```

**After:**
```dart
class UserService {
  final IErrorService _errorService = GetIt.instance<IErrorService>();

  Future<User?> getUser(String id) async {
    try {
      final response = await dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      // New way - centralized error handling
      _errorService.showApiError(ApiError(
        message: _getErrorMessage(e),
        statusCode: e.response?.statusCode ?? 0,
        endpoint: '/api/users/$id',
        method: 'GET',
        responseData: e.response?.data,
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
      case 403:
        return 'Access denied';
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
            onPressed: () => _navigateToLogin(),
          ),
        ];
      case 404:
        return [
          ErrorAction(
            id: 'go_back',
            label: 'Go Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ];
      default:
        return [
          ErrorAction(
            id: 'retry',
            label: 'Retry',
            isPrimary: true,
            onPressed: () => getUser(id),
          ),
        ];
    }
  }
}
```

#### Step 2.2: Migrate Form Validation

**Before:**
```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  String? emailError;
  String? passwordError;
  bool showErrorDialog = false;

  void _validateForm() {
    setState(() {
      emailError = _emailController.text.isEmpty ? 'Email is required' : null;
      passwordError = _passwordController.text.isEmpty ? 'Password is required' : null;
      
      if (emailError != null || passwordError != null) {
        showErrorDialog = true;
      }
    });

    if (showErrorDialog) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Validation Error'),
          content: Text('Please fix the form errors'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
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
        ElevatedButton(
          onPressed: _validateForm,
          child: Text('Login'),
        ),
      ],
    );
  }
}
```

**After:**
```dart
class _LoginFormState extends State<LoginForm> {
  final _errorService = GetIt.instance<IErrorService>();

  void _validateForm() {
    final errors = <String, List<String>>{};

    if (_emailController.text.isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!_isValidEmail(_emailController.text)) {
      errors['email'] = ['Please enter a valid email address'];
    }

    if (_passwordController.text.isEmpty) {
      errors['password'] = ['Password is required'];
    } else if (_passwordController.text.length < 8) {
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
      FocusScope.of(context).requestFocus(_emailFocusNode);
    } else if (errors.containsKey('password')) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _validateForm,
          child: Text('Login'),
        ),
      ],
    );
  }
}
```

#### Step 2.3: Migrate Authentication Errors

**Before:**
```dart
class AuthService {
  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      await _saveTokens(response.data);
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text('Invalid email or password'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToForgotPassword();
                },
                child: Text('Forgot Password?'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
      return false;
    }
  }
}
```

**After:**
```dart
class AuthService {
  final IErrorService _errorService = GetIt.instance<IErrorService>();

  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      await _saveTokens(response.data);
      return true;
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
      return false;
    }
  }
}
```

### Phase 3: Migrate Medium-Priority Areas

#### Step 3.1: Migrate Network Error Handling

**Before:**
```dart
class NetworkService {
  Future<T?> makeRequest<T>(String endpoint) async {
    try {
      final response = await dio.get(endpoint);
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Server timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection';
      } else {
        message = 'Network error';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return null;
    }
  }
}
```

**After:**
```dart
class NetworkService {
  final IErrorService _errorService = GetIt.instance<IErrorService>();

  Future<T?> makeRequest<T>(String endpoint) async {
    try {
      final response = await dio.get(endpoint);
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      final networkError = _createNetworkError(e, endpoint);
      _errorService.showNetworkError(networkError);
      return null;
    }
  }

  NetworkError _createNetworkError(DioException e, String endpoint) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkError(
          message: 'Connection timed out. Please check your internet connection.',
          networkType: NetworkErrorType.timeout,
          timeout: e.requestOptions.connectTimeout,
          url: endpoint,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => makeRequest(endpoint),
            ),
            ErrorAction(
              id: 'check_connection',
              label: 'Check Connection',
              onPressed: () => _checkNetworkConnection(),
            ),
          ],
        );
      
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: 'Server is taking too long to respond.',
          networkType: NetworkErrorType.timeout,
          timeout: e.requestOptions.receiveTimeout,
          url: endpoint,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => makeRequest(endpoint),
            ),
          ],
        );
      
      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'No internet connection detected.',
          networkType: NetworkErrorType.noConnection,
          url: endpoint,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => makeRequest(endpoint),
            ),
            ErrorAction(
              id: 'work_offline',
              label: 'Work Offline',
              onPressed: () => _enableOfflineMode(),
            ),
          ],
        );
      
      default:
        return NetworkError(
          message: 'Network error occurred.',
          networkType: NetworkErrorType.serverError,
          url: endpoint,
        );
    }
  }
}
```

## Common Migration Patterns

### Pattern 1: Replace Direct SnackBar Usage

```dart
// Migration helper function
void migrateSnackBarToErrorService(
  String message, {
  ErrorSeverity severity = ErrorSeverity.error,
  List<ErrorAction>? actions,
}) {
  final errorService = GetIt.instance<IErrorService>();
  
  errorService.showError(ClientError(
    message: message,
    stackTrace: StackTrace.current.toString(),
    componentName: 'MigratedSnackBar',
    severity: severity,
    actions: actions,
  ));
}

// Usage during migration
// Replace this:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Operation failed')),
);

// With this:
migrateSnackBarToErrorService('Operation failed');
```

### Pattern 2: Replace AlertDialog Error Displays

```dart
// Migration helper for dialogs
void migrateAlertDialogToErrorService(
  String title,
  String message, {
  List<ErrorAction>? actions,
}) {
  final errorService = GetIt.instance<IErrorService>();
  
  errorService.showError(ClientError(
    message: '$title: $message',
    stackTrace: StackTrace.current.toString(),
    componentName: 'MigratedAlertDialog',
    severity: ErrorSeverity.critical,
    actions: actions ?? [
      ErrorAction(
        id: 'ok',
        label: 'OK',
        isPrimary: true,
        onPressed: () {}, // Auto-dismiss
      ),
    ],
  ));
}

// Usage during migration
// Replace this:
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

// With this:
migrateAlertDialogToErrorService(
  'Error',
  'Something went wrong',
);
```

### Pattern 3: Replace Custom Error State Management

```dart
// Before: Custom error state
class UserStore {
  bool isLoading = false;
  String? errorMessage;
  bool hasError = false;

  void setError(String message) {
    errorMessage = message;
    hasError = true;
    isLoading = false;
  }

  void clearError() {
    errorMessage = null;
    hasError = false;
  }
}

// After: Using error service
class UserStore {
  final IErrorService _errorService = GetIt.instance<IErrorService>();
  bool isLoading = false;

  void setError(String message, {String? endpoint, int? statusCode}) {
    isLoading = false;
    _errorService.showError(ApiError(
      message: message,
      statusCode: statusCode ?? 0,
      endpoint: endpoint ?? '/unknown',
      method: 'GET',
    ));
  }

  void clearError() {
    _errorService.clearAllErrors();
  }
}
```

## Backward Compatibility

### Gradual Migration Strategy

Create a compatibility layer that supports both old and new error handling:

```dart
class CompatibilityErrorService implements IErrorService {
  final IErrorService _newService;
  final bool _enableLegacyFallback;

  CompatibilityErrorService(
    this._newService, {
    bool enableLegacyFallback = true,
  }) : _enableLegacyFallback = enableLegacyFallback;

  @override
  void showError(AppError error) {
    try {
      _newService.showError(error);
    } catch (e) {
      if (_enableLegacyFallback) {
        _fallbackToLegacyError(error);
      } else {
        rethrow;
      }
    }
  }

  void _fallbackToLegacyError(AppError error) {
    // Fallback to old error handling if new system fails
    print('Fallback: ${error.message}');
    
    // You could show a basic SnackBar here as fallback
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text(error.message)),
    // );
  }

  // ... other methods
}
```

### Feature Flags for Migration

```dart
class FeatureFlags {
  static const bool useNewErrorSystem = true;
  static const bool enableErrorSystemDebug = false;
  static const bool fallbackToLegacyErrors = false;
}

class ConditionalErrorService {
  static void showError(String message) {
    if (FeatureFlags.useNewErrorSystem) {
      final errorService = GetIt.instance<IErrorService>();
      errorService.showError(ClientError(
        message: message,
        stackTrace: StackTrace.current.toString(),
        componentName: 'ConditionalError',
      ));
    } else {
      // Legacy error handling
      _showLegacyError(message);
    }
  }

  static void _showLegacyError(String message) {
    // Old error handling code
  }
}
```

## Testing Migration

### Test Both Old and New Systems

```dart
void main() {
  group('Migration Tests', () {
    testWidgets('should handle errors with new system', (tester) async {
      // Test new error system
      final errorService = TestErrorService();
      GetIt.instance.registerSingleton<IErrorService>(errorService);

      await tester.pumpWidget(MyApp());
      
      // Trigger error
      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Verify new system works
      expect(errorService.capturedErrors.length, equals(1));
      expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
    });

    testWidgets('should fallback to legacy system when needed', (tester) async {
      // Test fallback behavior
      final compatibilityService = CompatibilityErrorService(
        ThrowingErrorService(), // Service that always throws
        enableLegacyFallback: true,
      );

      GetIt.instance.registerSingleton<IErrorService>(compatibilityService);

      await tester.pumpWidget(MyApp());
      
      // Trigger error
      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Verify fallback works (check console output or other indicators)
      // This depends on your fallback implementation
    });
  });
}

class TestErrorService implements IErrorService {
  final List<AppError> capturedErrors = [];

  @override
  void showError(AppError error) {
    capturedErrors.add(error);
  }

  // ... other methods
}

class ThrowingErrorService implements IErrorService {
  @override
  void showError(AppError error) {
    throw Exception('Test exception');
  }

  // ... other methods
}
```

### Migration Validation Tests

```dart
void main() {
  group('Migration Validation', () {
    test('should migrate SnackBar usage correctly', () {
      // Test that old SnackBar calls are properly converted
      final testErrorService = TestErrorService();
      GetIt.instance.registerSingleton<IErrorService>(testErrorService);

      // Simulate old SnackBar call
      migrateSnackBarToErrorService('Test error message');

      // Verify conversion
      expect(testErrorService.capturedErrors.length, equals(1));
      expect(testErrorService.capturedErrors.first.message, equals('Test error message'));
    });

    test('should migrate AlertDialog usage correctly', () {
      final testErrorService = TestErrorService();
      GetIt.instance.registerSingleton<IErrorService>(testErrorService);

      // Simulate old AlertDialog call
      migrateAlertDialogToErrorService('Error Title', 'Error message');

      // Verify conversion
      expect(testErrorService.capturedErrors.length, equals(1));
      expect(testErrorService.capturedErrors.first.message, contains('Error Title'));
      expect(testErrorService.capturedErrors.first.message, contains('Error message'));
    });
  });
}
```

## Rollback Strategy

### Prepare for Rollback

```dart
class RollbackableErrorService implements IErrorService {
  final IErrorService _newService;
  final LegacyErrorHandler _legacyHandler;
  bool _useNewSystem;

  RollbackableErrorService(
    this._newService,
    this._legacyHandler, {
    bool useNewSystem = true,
  }) : _useNewSystem = useNewSystem;

  void rollbackToLegacy() {
    _useNewSystem = false;
  }

  void switchToNew() {
    _useNewSystem = true;
  }

  @override
  void showError(AppError error) {
    if (_useNewSystem) {
      try {
        _newService.showError(error);
      } catch (e) {
        // Auto-rollback on critical errors
        _useNewSystem = false;
        _legacyHandler.showError(error.message);
      }
    } else {
      _legacyHandler.showError(error.message);
    }
  }

  // ... other methods
}
```

### Rollback Checklist

1. **Backup old error handling code** before deletion
2. **Keep feature flags** to quickly disable new system
3. **Monitor error rates** after migration
4. **Have rollback scripts** ready
5. **Test rollback procedure** in staging environment

### Emergency Rollback

```dart
// emergency_rollback.dart
class EmergencyRollback {
  static void rollbackErrorSystem() {
    print('EMERGENCY ROLLBACK: Switching to legacy error system');
    
    // Disable new error system
    FeatureFlags.useNewErrorSystem = false;
    
    // Clear any existing errors
    try {
      final errorService = GetIt.instance<IErrorService>();
      errorService.clearAllErrors();
    } catch (e) {
      print('Failed to clear errors during rollback: $e');
    }
    
    // Re-register legacy error handler
    GetIt.instance.unregister<IErrorService>();
    GetIt.instance.registerSingleton<IErrorService>(
      LegacyErrorService(),
    );
    
    print('Rollback completed');
  }
}

// Usage in main.dart for emergency situations
void main() async {
  try {
    await ErrorModule.configureErrorModuleInjection(GetIt.instance);
  } catch (e) {
    print('Error system initialization failed: $e');
    EmergencyRollback.rollbackErrorSystem();
  }
  
  runApp(MyApp());
}
```

This migration guide provides a comprehensive approach to migrating from existing error handling to the new Shared Error UI System while maintaining stability and providing rollback options.