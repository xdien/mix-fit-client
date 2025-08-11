# Error System API Documentation

## Overview

The Shared Error UI System provides a centralized, reusable error handling and display solution for the entire Flutter application. This documentation covers the complete API for integrating and using the error system.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Services](#core-services)
3. [Error Models](#error-models)
4. [UI Components](#ui-components)
5. [State Management](#state-management)
6. [Configuration](#configuration)
7. [Best Practices](#best-practices)

## Quick Start

### Basic Setup

```dart
import 'package:core/di/error_module.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:get_it/get_it.dart';

// Initialize error module
await ErrorModule.configureErrorModuleInjection(GetIt.instance);

// Get services
final errorService = GetIt.instance<IErrorService>();
final errorStore = GetIt.instance<ErrorStore>();
```

### Basic Usage

```dart
// Show a simple error
errorService.showError(ApiError(
  message: 'Failed to load data',
  statusCode: 500,
  endpoint: '/api/data',
  method: 'GET',
));

// Show a validation error
errorService.showValidationError(ValidationError(
  message: 'Form validation failed',
  fieldErrors: {
    'email': ['Email is required', 'Invalid email format'],
    'password': ['Password is too short'],
  },
  formId: 'login-form',
));

// Clear a specific error
errorService.clearError(errorId);

// Clear all errors
errorService.clearAllErrors();
```

## Core Services

### IErrorService

The main interface for error management.

#### Methods

##### `showError(AppError error)`

Displays a generic error in the error system.

**Parameters:**
- `error` (AppError): The error to display

**Example:**
```dart
final error = ApiError(
  message: 'Server error occurred',
  statusCode: 500,
  endpoint: '/api/users',
  method: 'GET',
);

errorService.showError(error);
```

##### `showApiError(ApiError error)`

Displays an API-specific error with enhanced context.

**Parameters:**
- `error` (ApiError): The API error to display

**Example:**
```dart
errorService.showApiError(ApiError(
  message: 'Unauthorized access',
  statusCode: 401,
  endpoint: '/api/protected',
  method: 'POST',
  requestData: {'userId': 123},
  responseData: {'error': 'Token expired'},
));
```

##### `showValidationError(ValidationError error)`

Displays form validation errors with field-specific guidance.

**Parameters:**
- `error` (ValidationError): The validation error to display

**Example:**
```dart
errorService.showValidationError(ValidationError(
  message: 'Please correct the following errors',
  fieldErrors: {
    'email': ['Email is required'],
    'password': ['Password must be at least 8 characters'],
  },
  formId: 'registration-form',
));
```

##### `showNetworkError(NetworkError error)`

Displays network-related errors with connectivity context.

**Parameters:**
- `error` (NetworkError): The network error to display

**Example:**
```dart
errorService.showNetworkError(NetworkError(
  message: 'Connection timeout',
  networkType: NetworkErrorType.timeout,
  timeout: Duration(seconds: 30),
  url: '/api/slow-endpoint',
));
```

##### `clearError(String errorId)`

Removes a specific error from the display.

**Parameters:**
- `errorId` (String): The unique identifier of the error to clear

**Example:**
```dart
errorService.clearError('error-123');
```

##### `clearAllErrors()`

Removes all errors from the display.

**Example:**
```dart
errorService.clearAllErrors();
```

##### `errorStream`

A stream of active errors for reactive programming.

**Returns:** `Stream<List<AppError>>`

**Example:**
```dart
errorService.errorStream.listen((errors) {
  print('Active errors: ${errors.length}');
});
```

## Error Models

### AppError (Abstract Base Class)

Base class for all error types.

#### Properties

- `id` (String): Unique identifier for the error
- `message` (String): Human-readable error message
- `severity` (ErrorSeverity): Error severity level
- `type` (ErrorType): Type of error
- `timestamp` (DateTime): When the error occurred
- `metadata` (Map<String, dynamic>?): Additional error context
- `actions` (List<ErrorAction>?): Available user actions

#### Enums

```dart
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

enum ErrorType {
  api,
  network,
  validation,
  authentication,
  authorization,
  client,
  server,
  offline,
}
```

### ApiError

Represents errors from API calls.

#### Constructor

```dart
ApiError({
  required String message,
  required int statusCode,
  required String endpoint,
  required String method,
  Map<String, dynamic>? requestData,
  Map<String, dynamic>? responseData,
  ErrorSeverity severity = ErrorSeverity.error,
  Map<String, dynamic>? metadata,
  List<ErrorAction>? actions,
})
```

#### Properties

- `statusCode` (int): HTTP status code
- `endpoint` (String): API endpoint that failed
- `method` (String): HTTP method used
- `requestData` (Map<String, dynamic>?): Request payload
- `responseData` (Map<String, dynamic>?): Response data

#### Example

```dart
final apiError = ApiError(
  message: 'Failed to create user',
  statusCode: 422,
  endpoint: '/api/users',
  method: 'POST',
  requestData: {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
  responseData: {
    'errors': {
      'email': ['Email already exists'],
    },
  },
  severity: ErrorSeverity.error,
);
```

### ValidationError

Represents form validation errors.

#### Constructor

```dart
ValidationError({
  required String message,
  required Map<String, List<String>> fieldErrors,
  String? formId,
  ErrorSeverity severity = ErrorSeverity.warning,
  Map<String, dynamic>? metadata,
  List<ErrorAction>? actions,
})
```

#### Properties

- `fieldErrors` (Map<String, List<String>>): Field-specific error messages
- `formId` (String?): Identifier of the form that failed validation

#### Example

```dart
final validationError = ValidationError(
  message: 'Please fix the following errors',
  fieldErrors: {
    'email': ['Email is required', 'Invalid email format'],
    'password': ['Password must be at least 8 characters'],
    'confirmPassword': ['Passwords do not match'],
  },
  formId: 'user-registration',
);
```

### NetworkError

Represents network connectivity issues.

#### Constructor

```dart
NetworkError({
  required String message,
  required NetworkErrorType networkType,
  Duration? timeout,
  String? url,
  ErrorSeverity severity = ErrorSeverity.error,
  Map<String, dynamic>? metadata,
  List<ErrorAction>? actions,
})
```

#### Properties

- `networkType` (NetworkErrorType): Type of network error
- `timeout` (Duration?): Timeout duration if applicable
- `url` (String?): URL that failed

#### Enums

```dart
enum NetworkErrorType {
  noConnection,
  timeout,
  serverError,
  dnsError,
  sslError,
}
```

#### Example

```dart
final networkError = NetworkError(
  message: 'Request timed out',
  networkType: NetworkErrorType.timeout,
  timeout: Duration(seconds: 30),
  url: '/api/large-data',
);
```

### ClientError

Represents client-side application errors.

#### Constructor

```dart
ClientError({
  required String message,
  required String stackTrace,
  String? componentName,
  ErrorSeverity severity = ErrorSeverity.error,
  Map<String, dynamic>? metadata,
  List<ErrorAction>? actions,
})
```

#### Properties

- `stackTrace` (String): Error stack trace
- `componentName` (String?): Component where error occurred

#### Example

```dart
final clientError = ClientError(
  message: 'Null pointer exception',
  stackTrace: 'Stack trace here...',
  componentName: 'UserProfileWidget',
  severity: ErrorSeverity.critical,
);
```

### ErrorAction

Represents an action users can take to resolve errors.

#### Constructor

```dart
ErrorAction({
  required String id,
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
  bool isPrimary = false,
})
```

#### Properties

- `id` (String): Unique action identifier
- `label` (String): Display text for the action
- `onPressed` (VoidCallback): Function to execute when pressed
- `icon` (IconData?): Optional icon
- `isPrimary` (bool): Whether this is the primary action

#### Example

```dart
final retryAction = ErrorAction(
  id: 'retry',
  label: 'Retry',
  icon: Icons.refresh,
  isPrimary: true,
  onPressed: () {
    // Retry logic here
  },
);
```

## UI Components

### ErrorStatusBarWidget

Displays errors in the application toolbar.

#### Constructor

```dart
ErrorStatusBarWidget({
  Key? key,
  required ErrorStore errorStore,
  bool showNetworkStatus = true,
  bool allowMinimize = true,
})
```

#### Properties

- `errorStore` (ErrorStore): The error store to observe
- `showNetworkStatus` (bool): Whether to show network status
- `allowMinimize` (bool): Whether users can minimize the error bar

#### Example

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('My App'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: ErrorStatusBarWidget(
          errorStore: GetIt.instance<ErrorStore>(),
          showNetworkStatus: true,
          allowMinimize: true,
        ),
      ),
    ),
    body: MyAppContent(),
  );
}
```

### ErrorDialogWidget

Modal dialog for critical errors.

#### Constructor

```dart
ErrorDialogWidget({
  Key? key,
  required AppError error,
  VoidCallback? onDismiss,
})
```

#### Properties

- `error` (AppError): The error to display
- `onDismiss` (VoidCallback?): Callback when dialog is dismissed

#### Example

```dart
void showCriticalError(AppError error) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ErrorDialogWidget(
      error: error,
      onDismiss: () {
        Navigator.of(context).pop();
      },
    ),
  );
}
```

### ErrorSnackbarWidget

Non-intrusive error notifications.

#### Constructor

```dart
ErrorSnackbarWidget({
  Key? key,
  required AppError error,
  Duration? duration,
  VoidCallback? onDismiss,
})
```

#### Properties

- `error` (AppError): The error to display
- `duration` (Duration?): Auto-dismiss duration
- `onDismiss` (VoidCallback?): Callback when dismissed

#### Example

```dart
void showLowPriorityError(AppError error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: ErrorSnackbarWidget(
        error: error,
        duration: Duration(seconds: 5),
        onDismiss: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
```

## State Management

### ErrorStore

MobX store for error state management.

#### Observable Properties

- `activeErrors` (ObservableList<AppError>): Currently active errors
- `currentError` (AppError?): Currently displayed error
- `isOffline` (bool): Network connectivity status
- `networkQuality` (NetworkQuality): Network quality level
- `isErrorBarVisible` (bool): Error bar visibility state
- `isErrorBarMinimized` (bool): Error bar minimization state

#### Computed Properties

- `hasErrors` (bool): Whether there are active errors
- `priorityError` (AppError?): Highest priority error
- `shouldShowErrorBar` (bool): Whether error bar should be visible

#### Actions

- `addError(AppError error)`: Add an error to the store
- `removeError(String errorId)`: Remove an error by ID
- `clearAllErrors()`: Remove all errors
- `updateNetworkStatus(NetworkStatus status)`: Update network status
- `toggleErrorBarVisibility()`: Toggle error bar visibility
- `minimizeErrorBar()`: Minimize the error bar
- `expandErrorBar()`: Expand the error bar

#### Example Usage

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorStore = GetIt.instance<ErrorStore>();
    
    return Observer(
      builder: (context) {
        if (errorStore.hasErrors) {
          return Column(
            children: [
              ErrorStatusBarWidget(errorStore: errorStore),
              Expanded(child: MyContent()),
            ],
          );
        }
        
        return MyContent();
      },
    );
  }
}
```

## Configuration

### Error Module Configuration

Configure the error system during app initialization.

```dart
import 'package:core/di/error_module.dart';

Future<void> initializeApp() async {
  // Configure error module
  await ErrorModule.configureErrorModuleInjection(
    GetIt.instance,
    config: ErrorModuleConfig(
      maxQueueSize: 5,
      defaultTimeout: Duration(seconds: 30),
      enableNetworkMonitoring: true,
      enableErrorPersistence: true,
      logLevel: ErrorLogLevel.debug,
    ),
  );
}
```

### ErrorModuleConfig

Configuration options for the error system.

#### Properties

- `maxQueueSize` (int): Maximum number of active errors (default: 5)
- `defaultTimeout` (Duration): Default timeout for network requests
- `enableNetworkMonitoring` (bool): Enable network status monitoring
- `enableErrorPersistence` (bool): Persist critical errors across app restarts
- `logLevel` (ErrorLogLevel): Logging level for error system

### Network Monitoring Configuration

```dart
final networkConfig = NetworkMonitorConfig(
  checkInterval: Duration(seconds: 30),
  timeoutThreshold: Duration(seconds: 10),
  qualityThresholds: {
    NetworkQuality.excellent: Duration(milliseconds: 100),
    NetworkQuality.good: Duration(milliseconds: 500),
    NetworkQuality.fair: Duration(milliseconds: 1000),
    NetworkQuality.poor: Duration(milliseconds: 2000),
  },
);
```

## Best Practices

### 1. Error Categorization

Use appropriate error types for different scenarios:

```dart
// API errors
errorService.showApiError(ApiError(...));

// Form validation
errorService.showValidationError(ValidationError(...));

// Network issues
errorService.showNetworkError(NetworkError(...));

// Client-side errors
errorService.showError(ClientError(...));
```

### 2. Error Severity

Set appropriate severity levels:

```dart
// Critical errors that block user interaction
ApiError(
  message: 'Authentication failed',
  severity: ErrorSeverity.critical,
  // ...
);

// Warnings that don't block functionality
ValidationError(
  message: 'Some fields need attention',
  severity: ErrorSeverity.warning,
  // ...
);

// Informational messages
ApiError(
  message: 'Data saved successfully',
  severity: ErrorSeverity.info,
  // ...
);
```

### 3. Custom Actions

Provide meaningful actions for error resolution:

```dart
final error = ApiError(
  message: 'Failed to save data',
  statusCode: 500,
  endpoint: '/api/save',
  method: 'POST',
  actions: [
    ErrorAction(
      id: 'retry',
      label: 'Retry',
      isPrimary: true,
      onPressed: () => retryOperation(),
    ),
    ErrorAction(
      id: 'save_draft',
      label: 'Save as Draft',
      onPressed: () => saveDraft(),
    ),
    ErrorAction(
      id: 'discard',
      label: 'Discard Changes',
      onPressed: () => discardChanges(),
    ),
  ],
);
```

### 4. Error Context

Provide rich context for debugging:

```dart
final error = ApiError(
  message: 'User creation failed',
  statusCode: 422,
  endpoint: '/api/users',
  method: 'POST',
  requestData: userData,
  responseData: response.data,
  metadata: {
    'userId': currentUser.id,
    'timestamp': DateTime.now().toIso8601String(),
    'userAgent': userAgent,
    'sessionId': sessionId,
  },
);
```

### 5. Reactive Error Handling

Use streams for reactive error handling:

```dart
class MyService {
  final IErrorService _errorService;
  
  MyService(this._errorService);
  
  Future<void> performOperation() async {
    try {
      await apiCall();
    } catch (e) {
      _errorService.showError(
        ApiError.fromException(e),
      );
    }
  }
  
  void listenToErrors() {
    _errorService.errorStream.listen((errors) {
      // React to error changes
      if (errors.any((e) => e.severity == ErrorSeverity.critical)) {
        // Handle critical errors
      }
    });
  }
}
```

### 6. Testing Error Scenarios

Test error handling in your widgets:

```dart
testWidgets('should display error when API fails', (tester) async {
  final errorService = MockErrorService();
  final errorStore = ErrorStore();
  
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(
        errorService: errorService,
        errorStore: errorStore,
      ),
    ),
  );
  
  // Simulate error
  final error = ApiError(
    message: 'Test error',
    statusCode: 500,
    endpoint: '/api/test',
    method: 'GET',
  );
  
  errorService.showError(error);
  await tester.pumpAndSettle();
  
  // Verify error is displayed
  expect(find.text('Test error'), findsOneWidget);
});
```

### 7. Accessibility

Ensure error messages are accessible:

```dart
ErrorStatusBarWidget(
  errorStore: errorStore,
  semanticLabel: 'Error notifications',
  announceErrors: true, // Announce to screen readers
  highContrastMode: MediaQuery.of(context).highContrast,
)
```

### 8. Localization

Support multiple languages:

```dart
final error = ApiError(
  message: AppLocalizations.of(context).apiErrorMessage,
  statusCode: 500,
  endpoint: '/api/data',
  method: 'GET',
  actions: [
    ErrorAction(
      id: 'retry',
      label: AppLocalizations.of(context).retryLabel,
      onPressed: () => retry(),
    ),
  ],
);
```

## Migration Guide

### From Legacy Error Handling

If you're migrating from existing error handling:

1. **Replace direct error displays:**
   ```dart
   // Old way
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('Error occurred')),
   );
   
   // New way
   errorService.showError(ApiError(
     message: 'Error occurred',
     statusCode: 500,
     endpoint: '/api/endpoint',
     method: 'GET',
   ));
   ```

2. **Centralize error handling:**
   ```dart
   // Old way - scattered error handling
   try {
     await apiCall();
   } catch (e) {
     showDialog(context: context, builder: (context) => ErrorDialog());
   }
   
   // New way - centralized
   try {
     await apiCall();
   } catch (e) {
     errorService.showError(ApiError.fromException(e));
   }
   ```

3. **Update error widgets:**
   ```dart
   // Old way
   if (hasError) {
     return ErrorWidget(error: errorMessage);
   }
   
   // New way
   return Observer(
     builder: (context) {
       if (errorStore.hasErrors) {
         return ErrorStatusBarWidget(errorStore: errorStore);
       }
       return Container();
     },
   );
   ```

This completes the comprehensive API documentation for the Shared Error UI System. The system provides a robust, accessible, and user-friendly way to handle errors across your Flutter application.