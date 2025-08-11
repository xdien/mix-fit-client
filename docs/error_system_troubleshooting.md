# Error System Troubleshooting Guide

This guide helps you diagnose and resolve common issues when using the Shared Error UI System.

## Table of Contents

1. [Common Error Scenarios](#common-error-scenarios)
2. [Debugging Tools](#debugging-tools)
3. [Performance Issues](#performance-issues)
4. [Integration Problems](#integration-problems)
5. [Testing Issues](#testing-issues)
6. [FAQ](#faq)

## Common Error Scenarios

### 1. Service Not Found Errors

#### Problem
```
Error: GetIt: Object/factory with type IErrorService is not registered inside GetIt.
```

#### Diagnosis
The error module hasn't been properly initialized or registered.

#### Solutions

**Solution A: Initialize Error Module**
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add this line
  await ErrorModule.configureErrorModuleInjection(GetIt.instance);
  
  runApp(MyApp());
}
```

**Solution B: Check Registration Status**
```dart
// Add debugging to check registration
void debugGetItRegistration() {
  print('IErrorService registered: ${GetIt.instance.isRegistered<IErrorService>()}');
  print('ErrorStore registered: ${GetIt.instance.isRegistered<ErrorStore>()}');
  
  // List all registered types
  print('All registered types:');
  for (final type in GetIt.instance.allReadySync()) {
    print('- ${type.runtimeType}');
  }
}
```

**Solution C: Manual Registration (if needed)**
```dart
// If automatic registration fails
void manualErrorModuleSetup() {
  final getIt = GetIt.instance;
  
  if (!getIt.isRegistered<ErrorStore>()) {
    getIt.registerSingleton<ErrorStore>(ErrorStore());
  }
  
  if (!getIt.isRegistered<IErrorService>()) {
    getIt.registerSingleton<IErrorService>(
      ErrorService(getIt<ErrorStore>()),
    );
  }
}
```

### 2. Errors Not Displaying in UI

#### Problem
Errors are being sent to the service but not appearing in the user interface.

#### Diagnosis Steps

**Step 1: Check Error Store State**
```dart
// Add debugging to your widget
class DebugErrorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorStore = GetIt.instance<ErrorStore>();
    
    return Observer(
      builder: (context) {
        print('Error Store Debug:');
        print('- Has errors: ${errorStore.hasErrors}');
        print('- Active errors count: ${errorStore.activeErrors.length}');
        print('- Should show error bar: ${errorStore.shouldShowErrorBar}');
        print('- Is error bar visible: ${errorStore.isErrorBarVisible}');
        
        for (int i = 0; i < errorStore.activeErrors.length; i++) {
          final error = errorStore.activeErrors[i];
          print('- Error $i: ${error.message} (${error.severity})');
        }
        
        return errorStore.shouldShowErrorBar
            ? ErrorStatusBarWidget(errorStore: errorStore)
            : Container(
                color: Colors.red.withOpacity(0.1),
                child: Text('No errors to show'),
              );
      },
    );
  }
}
```

**Step 2: Verify Observer Usage**
```dart
// Incorrect - Missing Observer
Widget buildIncorrect() {
  final errorStore = GetIt.instance<ErrorStore>();
  return errorStore.shouldShowErrorBar  // This won't react to changes
      ? ErrorStatusBarWidget(errorStore: errorStore)
      : SizedBox.shrink();
}

// Correct - With Observer
Widget buildCorrect() {
  final errorStore = GetIt.instance<ErrorStore>();
  return Observer(
    builder: (context) => errorStore.shouldShowErrorBar
        ? ErrorStatusBarWidget(errorStore: errorStore)
        : SizedBox.shrink(),
  );
}
```

**Step 3: Check Widget Tree Integration**
```dart
// Make sure ErrorStatusBarWidget is in the widget tree
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        // Add error bar here
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Observer(
            builder: (context) {
              final errorStore = GetIt.instance<ErrorStore>();
              return errorStore.shouldShowErrorBar
                  ? ErrorStatusBarWidget(errorStore: errorStore)
                  : SizedBox.shrink();
            },
          ),
        ),
      ),
      body: MyContent(),
    );
  }
}
```

### 3. Memory Leaks and Performance Issues

#### Problem
App becomes slow or crashes due to memory leaks in error handling.

#### Diagnosis

**Check for Undisposed Subscriptions**
```dart
// Bad - Subscription not disposed
class BadWidget extends StatefulWidget {
  @override
  _BadWidgetState createState() => _BadWidgetState();
}

class _BadWidgetState extends State<BadWidget> {
  @override
  void initState() {
    super.initState();
    // This creates a memory leak
    GetIt.instance<IErrorService>().errorStream.listen((errors) {
      // Handle errors
    });
  }
  // Missing dispose method!
}

// Good - Proper subscription management
class GoodWidget extends StatefulWidget {
  @override
  _GoodWidgetState createState() => _GoodWidgetState();
}

class _GoodWidgetState extends State<GoodWidget> {
  late StreamSubscription _errorSubscription;

  @override
  void initState() {
    super.initState();
    _errorSubscription = GetIt.instance<IErrorService>()
        .errorStream
        .listen((errors) {
      // Handle errors
    });
  }

  @override
  void dispose() {
    _errorSubscription.cancel(); // Prevent memory leak
    super.dispose();
  }
}
```

**Monitor Error Queue Size**
```dart
// Add monitoring to detect queue overflow
class ErrorQueueMonitor {
  static void monitorErrorQueue() {
    final errorStore = GetIt.instance<ErrorStore>();
    
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (errorStore.activeErrors.length > 3) {
        print('Warning: Error queue has ${errorStore.activeErrors.length} errors');
        
        // Log error details
        for (final error in errorStore.activeErrors) {
          print('- ${error.runtimeType}: ${error.message}');
        }
      }
    });
  }
}
```

### 4. Duplicate Error Messages

#### Problem
Same error appears multiple times in the UI.

#### Solutions

**Solution A: Implement Error Deduplication**
```dart
class DeduplicatingErrorService implements IErrorService {
  final IErrorService _baseService;
  final Set<String> _recentErrorIds = {};
  Timer? _cleanupTimer;

  DeduplicatingErrorService(this._baseService) {
    _startCleanupTimer();
  }

  @override
  void showError(AppError error) {
    final errorKey = '${error.runtimeType}-${error.message}';
    
    if (!_recentErrorIds.contains(errorKey)) {
      _recentErrorIds.add(errorKey);
      _baseService.showError(error);
      
      // Remove from recent errors after 30 seconds
      Timer(Duration(seconds: 30), () {
        _recentErrorIds.remove(errorKey);
      });
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (_recentErrorIds.length > 100) {
        _recentErrorIds.clear();
      }
    });
  }
}
```

**Solution B: Check Error Source**
```dart
// Add error source tracking
class TrackedApiError extends ApiError {
  final String source;

  TrackedApiError({
    required super.message,
    required super.statusCode,
    required super.endpoint,
    required super.method,
    required this.source,
  });

  @override
  String get id => '${super.id}-$source';
}

// Usage
errorService.showError(TrackedApiError(
  message: 'Failed to load data',
  statusCode: 500,
  endpoint: '/api/data',
  method: 'GET',
  source: 'UserService.loadUser', // Helps identify duplicate sources
));
```

### 5. Network Error Handling Issues

#### Problem
Network errors not being handled correctly or showing confusing messages.

#### Solutions

**Improve Network Error Detection**
```dart
class NetworkErrorHandler {
  static NetworkError createFromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkError(
          message: 'Connection timed out. Please check your internet connection.',
          networkType: NetworkErrorType.timeout,
          timeout: e.requestOptions.connectTimeout,
          url: e.requestOptions.path,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => _retryRequest(e.requestOptions),
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
          url: e.requestOptions.path,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Try Again',
              isPrimary: true,
              onPressed: () => _retryRequest(e.requestOptions),
            ),
          ],
        );

      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'Unable to connect to server. Please check your internet connection.',
          networkType: NetworkErrorType.noConnection,
          url: e.requestOptions.path,
          actions: [
            ErrorAction(
              id: 'retry',
              label: 'Retry',
              isPrimary: true,
              onPressed: () => _retryRequest(e.requestOptions),
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
          message: 'Network error occurred: ${e.message}',
          networkType: NetworkErrorType.serverError,
          url: e.requestOptions.path,
        );
    }
  }

  static Future<void> _retryRequest(RequestOptions options) async {
    // Implement retry logic
  }

  static Future<void> _checkNetworkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      // Show offline message
    } else {
      // Show connection available message
    }
  }

  static void _enableOfflineMode() {
    // Enable offline functionality
  }
}
```

## Debugging Tools

### 1. Error System Debug Panel

Create a debug panel to monitor error system state:

```dart
class ErrorSystemDebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorStore = GetIt.instance<ErrorStore>();
    
    return Observer(
      builder: (context) => ExpansionTile(
        title: Text('Error System Debug (${errorStore.activeErrors.length} errors)'),
        children: [
          _buildErrorStoreInfo(errorStore),
          _buildActiveErrorsList(errorStore),
          _buildErrorActions(),
        ],
      ),
    );
  }

  Widget _buildErrorStoreInfo(ErrorStore errorStore) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error Store State:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Has Errors: ${errorStore.hasErrors}'),
            Text('Should Show Error Bar: ${errorStore.shouldShowErrorBar}'),
            Text('Is Error Bar Visible: ${errorStore.isErrorBarVisible}'),
            Text('Is Error Bar Minimized: ${errorStore.isErrorBarMinimized}'),
            Text('Is Offline: ${errorStore.isOffline}'),
            Text('Network Quality: ${errorStore.networkQuality}'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveErrorsList(ErrorStore errorStore) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...errorStore.activeErrors.map((error) => Padding(
              padding: EdgeInsets.only(left: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: ${error.runtimeType}'),
                  Text('Message: ${error.message}'),
                  Text('Severity: ${error.severity}'),
                  Text('ID: ${error.id}'),
                  Text('Timestamp: ${error.timestamp}'),
                  if (error.actions != null)
                    Text('Actions: ${error.actions!.map((a) => a.label).join(', ')}'),
                  Divider(),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorActions() {
    final errorService = GetIt.instance<IErrorService>();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _createTestError(errorService),
                  child: Text('Create Test Error'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => errorService.clearAllErrors(),
                  child: Text('Clear All Errors'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createTestError(IErrorService errorService) {
    errorService.showError(ApiError(
      message: 'Test error created at ${DateTime.now()}',
      statusCode: 500,
      endpoint: '/api/test',
      method: 'GET',
    ));
  }
}
```

### 2. Error Logging

Implement comprehensive error logging:

```dart
class ErrorLogger {
  static final List<ErrorLogEntry> _logs = [];
  static const int maxLogs = 1000;

  static void logError(AppError error, String action) {
    final entry = ErrorLogEntry(
      error: error,
      action: action,
      timestamp: DateTime.now(),
      stackTrace: StackTrace.current.toString(),
    );

    _logs.insert(0, entry);
    
    if (_logs.length > maxLogs) {
      _logs.removeRange(maxLogs, _logs.length);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      print('ERROR LOG: $action - ${error.runtimeType}: ${error.message}');
    }
  }

  static List<ErrorLogEntry> getLogs({int? limit}) {
    return limit != null ? _logs.take(limit).toList() : _logs;
  }

  static void clearLogs() {
    _logs.clear();
  }

  static String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('Error System Logs - Generated: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    
    for (final entry in _logs) {
      buffer.writeln('Timestamp: ${entry.timestamp}');
      buffer.writeln('Action: ${entry.action}');
      buffer.writeln('Error Type: ${entry.error.runtimeType}');
      buffer.writeln('Message: ${entry.error.message}');
      buffer.writeln('Severity: ${entry.error.severity}');
      if (entry.error is ApiError) {
        final apiError = entry.error as ApiError;
        buffer.writeln('Status Code: ${apiError.statusCode}');
        buffer.writeln('Endpoint: ${apiError.endpoint}');
        buffer.writeln('Method: ${apiError.method}');
      }
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }
}

class ErrorLogEntry {
  final AppError error;
  final String action;
  final DateTime timestamp;
  final String stackTrace;

  ErrorLogEntry({
    required this.error,
    required this.action,
    required this.timestamp,
    required this.stackTrace,
  });
}

// Usage in ErrorService
class LoggingErrorService implements IErrorService {
  final IErrorService _baseService;

  LoggingErrorService(this._baseService);

  @override
  void showError(AppError error) {
    ErrorLogger.logError(error, 'SHOW');
    _baseService.showError(error);
  }

  @override
  void clearError(String errorId) {
    ErrorLogger.logError(
      ClientError(message: 'Cleared error: $errorId', stackTrace: ''),
      'CLEAR',
    );
    _baseService.clearError(errorId);
  }

  @override
  void clearAllErrors() {
    ErrorLogger.logError(
      ClientError(message: 'Cleared all errors', stackTrace: ''),
      'CLEAR_ALL',
    );
    _baseService.clearAllErrors();
  }

  // ... other methods
}
```

## Performance Issues

### 1. Slow Error Display

#### Problem
Errors take a long time to appear or cause UI lag.

#### Solutions

**Optimize Observer Usage**
```dart
// Bad - Observer wrapping large widget tree
Observer(
  builder: (context) => Scaffold(
    appBar: AppBar(/* ... */),
    body: Column(
      children: [
        // Large widget tree
        ComplexWidget(),
        AnotherComplexWidget(),
        // Error bar at the end
        errorStore.shouldShowErrorBar
            ? ErrorStatusBarWidget(errorStore: errorStore)
            : SizedBox.shrink(),
      ],
    ),
  ),
);

// Good - Observer only around error-specific widget
Scaffold(
  appBar: AppBar(/* ... */),
  body: Column(
    children: [
      ComplexWidget(),
      AnotherComplexWidget(),
      // Observer only around error bar
      Observer(
        builder: (context) => errorStore.shouldShowErrorBar
            ? ErrorStatusBarWidget(errorStore: errorStore)
            : SizedBox.shrink(),
      ),
    ],
  ),
);
```

**Use Computed Properties Efficiently**
```dart
// In ErrorStore
@computed
bool get shouldShowErrorBar {
  // Cache expensive computations
  return hasErrors || isOffline || hasWarnings;
}

@computed
AppError? get priorityError {
  if (activeErrors.isEmpty) return null;
  
  // Sort by priority only when needed
  final sortedErrors = activeErrors.toList()
    ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  
  return sortedErrors.first;
}
```

### 2. Memory Usage Issues

#### Problem
Error system consuming too much memory.

#### Solutions

**Implement Error Queue Limits**
```dart
class MemoryEfficientErrorStore extends ErrorStore {
  static const int maxActiveErrors = 5;
  static const int maxErrorHistory = 50;

  @override
  void addError(AppError error) {
    super.addError(error);
    
    // Limit active errors
    while (activeErrors.length > maxActiveErrors) {
      final oldestError = activeErrors.last;
      removeError(oldestError.id);
    }
    
    // Limit error history
    while (errorHistory.length > maxErrorHistory) {
      errorHistory.removeLast();
    }
  }
}
```

**Clean Up Error References**
```dart
class ErrorCleanupService {
  static Timer? _cleanupTimer;

  static void startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _performCleanup();
    });
  }

  static void _performCleanup() {
    final errorStore = GetIt.instance<ErrorStore>();
    
    // Remove old errors
    final now = DateTime.now();
    final oldErrors = errorStore.activeErrors
        .where((error) => now.difference(error.timestamp) > Duration(minutes: 30))
        .toList();
    
    for (final error in oldErrors) {
      errorStore.removeError(error.id);
    }
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      print('Cleaned up ${oldErrors.length} old errors');
    }
  }

  static void stopCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}
```

## Integration Problems

### 1. Conflicts with Existing Error Handling

#### Problem
New error system conflicts with existing error handling code.

#### Solution
Create a migration wrapper:

```dart
class MigrationErrorService implements IErrorService {
  final IErrorService _newService;
  final LegacyErrorHandler _legacyHandler;
  final bool _useLegacyForCritical;

  MigrationErrorService(
    this._newService,
    this._legacyHandler, {
    bool useLegacyForCritical = false,
  }) : _useLegacyForCritical = useLegacyForCritical;

  @override
  void showError(AppError error) {
    if (_useLegacyForCritical && error.severity == ErrorSeverity.critical) {
      _legacyHandler.showError(error.message);
    } else {
      _newService.showError(error);
    }
  }

  // Gradually migrate by changing _useLegacyForCritical to false
}
```

### 2. Testing Environment Issues

#### Problem
Error system behaves differently in tests.

#### Solution
Create test-specific error service:

```dart
class TestErrorService implements IErrorService {
  final List<AppError> capturedErrors = [];
  final List<String> clearedErrorIds = [];

  @override
  void showError(AppError error) {
    capturedErrors.add(error);
  }

  @override
  void clearError(String errorId) {
    clearedErrorIds.add(errorId);
    capturedErrors.removeWhere((error) => error.id == errorId);
  }

  @override
  void clearAllErrors() {
    capturedErrors.clear();
  }

  @override
  Stream<List<AppError>> get errorStream => Stream.value(capturedErrors);

  // Test helpers
  bool hasErrorWithMessage(String message) {
    return capturedErrors.any((error) => error.message.contains(message));
  }

  AppError? getLastError() {
    return capturedErrors.isNotEmpty ? capturedErrors.last : null;
  }

  void reset() {
    capturedErrors.clear();
    clearedErrorIds.clear();
  }
}

// Usage in tests
void main() {
  group('My Service Tests', () {
    late TestErrorService testErrorService;
    late MyService myService;

    setUp(() {
      testErrorService = TestErrorService();
      myService = MyService(testErrorService);
    });

    test('should show error when operation fails', () async {
      // Act
      await myService.performOperation();

      // Assert
      expect(testErrorService.capturedErrors.length, equals(1));
      expect(testErrorService.hasErrorWithMessage('Operation failed'), isTrue);
    });
  });
}
```

## Testing Issues

### Common Testing Problems and Solutions

#### 1. GetIt Registration Issues in Tests

```dart
// Problem: GetIt state persists between tests
void main() {
  group('Error Service Tests', () {
    setUp(() {
      // Always reset GetIt before each test
      GetIt.instance.reset();
      
      // Register test dependencies
      GetIt.instance.registerSingleton<ErrorStore>(MockErrorStore());
      GetIt.instance.registerSingleton<IErrorService>(
        ErrorService(GetIt.instance<ErrorStore>()),
      );
    });

    tearDown(() {
      // Clean up after each test
      GetIt.instance.reset();
    });

    // Tests here...
  });
}
```

#### 2. Async Error Handling in Tests

```dart
// Problem: Async errors not being caught in tests
test('should handle async errors correctly', () async {
  // Arrange
  final errorService = TestErrorService();
  final myService = MyService(errorService);

  // Act
  await myService.performAsyncOperation();

  // Wait for async error processing
  await Future.delayed(Duration(milliseconds: 100));

  // Assert
  expect(errorService.capturedErrors.length, equals(1));
});
```

## FAQ

### Q: Why are my errors not showing up?

**A:** Check these common issues:
1. Error module not initialized
2. Missing Observer wrapper
3. ErrorStatusBarWidget not in widget tree
4. Error severity too low (info errors might be auto-dismissed)

### Q: How do I customize error messages?

**A:** Override the error message when creating errors:
```dart
errorService.showApiError(ApiError(
  message: 'Custom error message here',
  statusCode: 500,
  endpoint: '/api/endpoint',
  method: 'GET',
));
```

### Q: Can I disable certain types of errors?

**A:** Yes, create a filtering error service:
```dart
class FilteringErrorService implements IErrorService {
  final IErrorService _baseService;
  final Set<Type> _disabledTypes;

  FilteringErrorService(this._baseService, this._disabledTypes);

  @override
  void showError(AppError error) {
    if (!_disabledTypes.contains(error.runtimeType)) {
      _baseService.showError(error);
    }
  }
}
```

### Q: How do I handle errors in background tasks?

**A:** Use the error service from background isolates:
```dart
void backgroundTask() async {
  try {
    // Background work
  } catch (e) {
    // Send error to main isolate
    final errorData = {
      'message': 'Background task failed',
      'error': e.toString(),
    };
    
    // Use SendPort to communicate with main isolate
    sendPort.send(errorData);
  }
}
```

### Q: Can I persist errors across app restarts?

**A:** Yes, for critical errors:
```dart
errorService.showError(ApiError(
  message: 'Critical system error',
  statusCode: 500,
  endpoint: '/api/critical',
  method: 'GET',
  severity: ErrorSeverity.critical,
  metadata: {
    'persist': true, // Custom flag for persistence
  },
));
```

This troubleshooting guide should help you resolve most common issues with the Error System. If you encounter issues not covered here, check the error logs and use the debugging tools provided.